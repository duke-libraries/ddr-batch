require 'rails_helper'

module Ddr::Batch

  shared_examples "a valid ingest object" do
    it "should be valid" do
      expect(object.validate).to be_empty
    end
  end

  shared_examples "an invalid ingest object" do
    it "should not be valid" do
      expect(object.validate).to include(error_message)
    end
  end

  shared_examples "a successful ingest" do
    let(:repo_object) { ActiveFedora::Base.find(object.pid) }
    let(:verification_event) { repo_object.events.select { |e| e.is_a? Ddr::Events::ValidationEvent }.first }
    before { object.process(user) }
    it "should result in a verified repository object" do
      expect(object.verified).to be_truthy
      expect(object.pid).to eq(assigned_pid) if assigned_pid.present?
      unless object.batch_object_attributes.empty?
        expect(repo_object.dc_title).to eq(["Test Object Title"])
        expect(verification_event.detail).to include("title attribute set correctly...#{BatchObject::VERIFICATION_PASS}")
      end
    end
  end

  describe IngestBatchObject, type: :model, batch: true, ingest: true do

    context "validate" do

      context "relationships" do
        let(:object) { FactoryGirl.create(:generic_ingest_batch_object) }
        it "should valdiate the relationships" do
          object.batch_object_relationships.each do |r|
            expect(r).to receive(:valid?)
          end
          object.validate
        end
      end

      context "valid object" do
        context "generic object" do
          let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_bytes) }
          it_behaves_like "a valid ingest object"
        end
        context "target object" do
          let(:object) { FactoryGirl.create(:target_ingest_batch_object) }
          it_behaves_like "a valid ingest object"
        end
      end

      context "invalid object" do
        let(:error_prefix) { "#{object.identifier} [Database ID: #{object.id}]:"}
        context "missing model" do
          let(:object) { FactoryGirl.create(:ingest_batch_object) }
          let(:error_message) { "#{error_prefix} Model required for INGEST operation" }
          it_behaves_like "an invalid ingest object"
        end
        context "invalid model" do
          let(:object) { FactoryGirl.create(:ingest_batch_object) }
          let(:error_message) { "#{error_prefix} Invalid model name: #{object.model}" }
          before { object.model = "BadModel" }
          it_behaves_like "an invalid ingest object"
        end
        context "invalid datastreams" do
          let(:object) { FactoryGirl.create(:ingest_batch_object, :has_model, :with_add_extracted_text_datastream_bytes, :with_add_content_datastream) }
          context "invalid datastream name" do
            let(:error_message) { "#{error_prefix} Invalid datastream name for #{object.model}: #{object.batch_object_datastreams.first[:name]}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.name = "invalid_name"
              datastream.save!
            end
            it_behaves_like "an invalid ingest object"
          end
          context "invalid payload type" do
            let(:error_message) { "#{error_prefix} Invalid payload type for #{object.batch_object_datastreams.first[:name]} datastream: #{object.batch_object_datastreams.first[:payload_type]}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.payload_type = "invalid_type"
              datastream.save!
            end
            it_behaves_like "an invalid ingest object"
          end
          context "missing data file" do
            let(:error_message) { "#{error_prefix} Missing or unreadable file for #{object.batch_object_datastreams.last[:name]} datastream: #{object.batch_object_datastreams.last[:payload]}" }
            before do
              datastream = object.batch_object_datastreams.last
              datastream.payload = "non_existent_file.xml"
              datastream.save!
            end
            it_behaves_like "an invalid ingest object"
          end
          context "checksum without checksum type" do
            let(:error_message) { "#{error_prefix} Must specify checksum type if providing checksum for #{object.batch_object_datastreams.first.name} datastream" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.checksum = "123456"
              datastream.checksum_type = nil
              datastream.save!
            end
            it_behaves_like "an invalid ingest object"
          end
          context "invalid checksum type" do
            let(:error_message) { "#{error_prefix} Invalid checksum type for #{object.batch_object_datastreams.first.name} datastream: #{object.batch_object_datastreams.first.checksum_type}" }
            before do
              datastream = object.batch_object_datastreams.first
              datastream.checksum_type = "SHA-INVALID"
              datastream.save!
            end
            it_behaves_like "an invalid ingest object"
          end
        end
      end
    end

    context "ingest" do

      let(:user) { FactoryGirl.create(:user) }
      context "successful ingest" do
        context "not previously ingested object" do
          let(:assigned_pid) { nil }
          context "payload type bytes" do
            let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_bytes) }
            it_behaves_like "a successful ingest"
          end
          context "payload type file" do
            let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_file) }
            it_behaves_like "a successful ingest"
          end
          context "attributes" do
            let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_attributes) }
            it_behaves_like "a successful ingest"
          end
          context "relationship with record ID object" do
            let(:batch) { Ddr::Batch::Batch.create }
            let(:parent_repo_object) { TestParent.create }
            let(:parent_object) do
              Ddr::Batch::IngestBatchObject.create(
                  batch: batch,
                  model: 'TestParent',
                  pid: parent_repo_object.id)
            end
            let(:object) do
              Ddr::Batch::IngestBatchObject.create(
                  batch: batch,
                  model: 'TestChild')
            end
            let(:relationship) do
              BatchObjectRelationship.new(
                operation: BatchObjectRelationship::OPERATION_ADD,
                name: BatchObjectRelationship::RELATIONSHIP_PARENT,
                object_type: BatchObjectRelationship::OBJECT_TYPE_REC_ID,
                object:parent_object.id
              )
            end
            before do
              object.batch_object_relationships << relationship
              object.save
            end
            it_behaves_like "a successful ingest"
          end
        end
        context "previously ingested object (e.g., during restart)" do
          let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_bytes) }
          let(:assigned_pid) { SecureRandom.uuid }
          before do
            object.pid = assigned_pid
            object.verified = true
            object.save
            repo_object = object.model.constantize.new(:pid => assigned_pid, dc_title: ["Test Object Title"])
            repo_object.save(validate: false)
          end
          it_behaves_like "a successful ingest"
        end
      end

      context "exception during ingest" do
        let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_bytes) }
        before { allow_any_instance_of(IngestBatchObject).to receive(:populate_datastream).and_raise(RuntimeError) }
        context "error during processing" do
          it "should log a fatal message and re-raise the exception" do
            expect(Rails.logger).to receive(:fatal).with(/Error in creating repository object/)
            expect { object.process(user) }.to raise_error(RuntimeError)
          end
        end
        context "error while destroying repository object" do
          before { allow_any_instance_of(TestModelOmnibus).to receive(:destroy).and_raise(RuntimeError) }
          after { allow_any_instance_of(TestModelOmnibus).to receive(:destroy).and_call_original }
          it "should log two fatal messages and re-raise the initial exception" do
            expect(Rails.logger).to receive(:fatal).with(/Error in creating repository object/)
            expect(Rails.logger).to receive(:fatal).with(/Error deleting repository object/)
            expect { object.process(user) }.to raise_error(RuntimeError)
          end
        end
      end

      context "external checksum verification failure" do
        let(:object) { FactoryGirl.create(:generic_ingest_batch_object_with_bytes) }
        before do
          object.batch_object_datastreams.each do |ds|
            if ds.name == "content"
              ds.checksum = "badabcdef0123456789"
              object.save!
            end
          end
        end
        it "should not result in a verified ingest" do
          object.process(user)
          expect(object.verified).to be_falsey
          ActiveFedora::Base.find(object.pid).events.each do |e|
            if e.is_a?(Ddr::Events::ValidationEvent)
              expect(e.outcome).to eq(Ddr::Events::Event::FAILURE)
              expect(e.detail).to include("content external checksum match...FAIL")
            end
          end
        end
      end

    end

  end

end