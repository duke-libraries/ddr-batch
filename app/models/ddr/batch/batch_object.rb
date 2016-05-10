module Ddr::Batch

    # This is a superclass containing methods common to all batch object objects.  It is not intended to be instantiated directly.
    # This superclass and its subclasses are designed following the ActiveRecord single-table inheritance pattern.
    class BatchObject < ActiveRecord::Base

      belongs_to :batch, inverse_of: :batch_objects
      has_many :batch_object_attributes, -> { order "id ASC" }, inverse_of: :batch_object, dependent: :destroy
      has_many :batch_object_files, inverse_of: :batch_object, dependent: :destroy
      has_many :batch_object_relationships, inverse_of: :batch_object, dependent: :destroy

      VERIFICATION_PASS = "PASS"
      VERIFICATION_FAIL = "FAIL"

      EVENT_SUMMARY = <<-EOS
  %{label}
  Batch object database id: %{batch_id}
  Batch object identifier: %{identifier}
  Model: %{model}
      EOS

      def self.pid_from_identifier(identifier, batch_id)
        query = "identifier = :identifier"
        query << " and batch_id = :batch_id" if batch_id
        params = { :identifier => identifier }
        params[:batch_id] = batch_id if batch_id
        sort = "updated_at asc"
        found_objects = BatchObject.where(query, params).order(sort)
        pids = []
        found_objects.each { |obj| pids << obj.pid }
        return pids
      end

      def error_prefix
        I18n.t('ddr.batch.errors.prefix', :identifier => identifier, :id => id)
      end

      def validate
        errors = []
        errors += validate_model if model
        errors += validate_files if batch_object_files
        errors += validate_relationships if batch_object_relationships
        errors += local_validations
        return errors
      end

      def local_validations
        []
      end

      def model_file_keys
        raise NotImplementedError
      end

      def process(user, opts = {})
        raise NotImplementedError
      end

      def results_message
        raise NotImplementedError
      end

      Results = Struct.new(:repository_object, :verified, :verifications)

      private

      def validate_model
        errs = []
        begin
          model.constantize
        rescue NameError
          errs << "#{error_prefix} Invalid model name: #{model}"
        end
        return errs
      end

      def validate_files
        errs = []
        batch_object_files.each do |f|
          if model_file_keys.present?
            unless model_file_keys.include?(f.name.to_sym)
              errs << "#{error_prefix} Invalid file name for #{model}: #{f.name}"
            end
          end
          unless BatchObjectFile::PAYLOAD_TYPES.include?(f.payload_type)
            errs << "#{error_prefix} Invalid payload type for #{f.name} file: #{f.payload_type}"
          end
          if f.payload_type.eql?(BatchObjectFile::PAYLOAD_TYPE_FILENAME)
            unless File.readable?(f.payload)
              errs << "#{error_prefix} Missing or unreadable file for #{f[:name]} file: #{f[:payload]}"
            end
          end
          if f.checksum && !f.checksum_type
            errs << "#{error_prefix} Must specify checksum type if providing checksum for #{f.name} file"
          end
          if f.checksum_type
            unless f.checksum_type == Ddr::Models::File::CHECKSUM_TYPE_SHA1
              errs << "#{error_prefix} Invalid checksum type for #{f.name} file: #{f.checksum_type}"
            end
          end
        end
        return errs
      end

      def validate_relationships
        errs = []
        batch_object_relationships.each do |r|
          r.valid?
          errs += r.errors.messages.values.map { |msg| "#{error_prefix} msg" }
        end
        return errs
      end

      def verify_repository_object
        verifications = {}
        begin
          repo_object = ActiveFedora::Base.find(pid)
        rescue ActiveFedora::ObjectNotFoundError
          verifications["Object exists in repository"] = VERIFICATION_FAIL
        else
          verifications["Object exists in repository"] = VERIFICATION_PASS
          verifications["Object is correct model"] = verify_model(repo_object) if model
          unless batch_object_attributes.empty?
            batch_object_attributes.each do |a|
              if a.operation == BatchObjectAttribute::OPERATION_ADD
                verifications["#{a.name} attribute set correctly"] = verify_attribute(repo_object, a)
              end
            end
          end
          unless batch_object_files.empty?
            batch_object_files.each do |d|
              verifications["#{d.name} file present and not empty"] = verify_file(repo_object, d)
              verifications["#{d.name} external checksum match"] = verify_file_external_checksum(repo_object, d) if d.checksum
            end
          end
          unless batch_object_relationships.empty?
            batch_object_relationships.each do |r|
              verifications["#{r.name} relationship is correct"] = verify_relationship(repo_object, r)
            end
          end
          result = repo_object.check_fixity
          verifications["Fixity check"] = result.success? ? VERIFICATION_PASS : VERIFICATION_FAIL
        end
        verifications
      end

      def verify_model(repo_object)
        begin
          if repo_object.class.eql?(model.constantize)
            return VERIFICATION_PASS
          else
            return VERIFICATION_FAIL
          end
        rescue NameError
          return VERIFICATION_FAIL
        end
      end

      def verify_attribute(repo_object, attribute)
        verified = case attribute.metadata
          when Ddr::Models::Metadata::DESC_METADATA
            repo_object.desc_metadata.values(attribute.name).include?(attribute.value)
          when Ddr::Models::Metadata::ADMIN_METADATA
            repo_object.admin_metadata.values(attribute.name).include?(attribute.value)
        end
        verified ? VERIFICATION_PASS : VERIFICATION_FAIL
      end

      def verify_file(repo_object, file)
        if repo_object.attached_files.include?(file.name) &&
            repo_object.attached_files[file.name].has_content?
          VERIFICATION_PASS
        else
          VERIFICATION_FAIL
        end
      end

      def verify_file_external_checksum(repo_object, file)
        repo_object.attached_files[file.name].validate_checksum! file.checksum, file.checksum_type
        return VERIFICATION_PASS
      rescue Ddr::Models::ChecksumInvalid
        return VERIFICATION_FAIL
      end

      def verify_relationship(repo_object, relationship)
        # if PID, proceed as below
        # if AR rec ID,
        #   retrieve AR rec
        #   if AR rec has PID, proceed as below using AR rec PID
        #   if not, error (should not occur)
        repo_object_id = case
                           when relationship.object_rec_id?
                             referent = batch.batch_objects.find(relationship.object)
                             referent.pid
                           when relationship.object_repo_id?
                             relationship.object
                         end
        relationship_reflection = Ddr::Utils.relationship_object_reflection(model, relationship.name)
        relationship_object_class = Ddr::Utils.reflection_object_class(relationship_reflection)
        relationship_object = repo_object.send(relationship.name)
        if !relationship_object.nil? &&
            relationship_object.id.eql?(repo_object_id) &&
            relationship_object.is_a?(relationship_object_class)
          VERIFICATION_PASS
        else
          VERIFICATION_FAIL
        end
      end

      def add_attribute(repo_object, attribute)
        repo_object.send(attribute.metadata).add_value(attribute.name, attribute.value)
        return repo_object
      end

      def clear_attribute(repo_object, attribute)
        repo_object.send(attribute.metadata).set_values(attribute.name, nil)
        return repo_object
      end

      def clear_attributes(repo_object, attribute)
        Ddr::Models::DescriptiveMetadata.unqualified_names.each do |term|
          repo_object.desc_metadata.set_values(term, nil) if repo_object.desc_metadata.values(term)
        end
        return repo_object
      end

      def populate_file(repo_object, file)
        case file[:payload_type]
        when BatchObjectFile::PAYLOAD_TYPE_BYTES
          file_content = file[:payload]
          repo_object.attached_files[file[:name]].content = file_content
        when BatchObjectFile::PAYLOAD_TYPE_FILENAME
          file_content = File.new(file[:payload])
          file_name = File.basename(file[:payload])
          file_id = file[:name]
          repo_object.add_file(file_content, path: file_id)
        end
        return repo_object
      end

      def add_relationship(repo_object, relationship)
        repo_object_id = case
                           when relationship.object_rec_id?
                             referent = batch.batch_objects.find(relationship[:object])
                             referent.pid
                           when relationship.object_repo_id?
                             relationship[:object]
                         end
        if repo_object_id.present?
          relationship_object = ActiveFedora::Base.find(repo_object_id)
          repo_object.send("#{relationship[:name]}=", relationship_object)
        else
          raise Ddr::Batch::Error, "Unable to determine repository ID for relationship #{relationship.id}"
        end
        return repo_object
      end

      def set_rdf_subject(repo_object, file_content)
        graph = RDF::Graph.new
        RDF::Reader.for(:ntriples).new(file_content) do |reader|
          reader.each_statement do |statement|
            if statement.subject.is_a? RDF::Node
              statement.subject = RDF::URI(repo_object.internal_uri)
            end
            graph.insert(statement)
          end
        end
        graph.dump :ntriples
      end

    end


end
