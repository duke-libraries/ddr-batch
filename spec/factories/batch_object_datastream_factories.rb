FactoryGirl.define do
  factory :batch_object_datastream, :class => Ddr::Batch::BatchObjectDatastream do

    factory :batch_object_add_datastream do
      operation Ddr::Batch::BatchObjectDatastream::OPERATION_ADD

      factory :batch_object_add_extracted_text_datastream_bytes do
        name Ddr::Datastreams::EXTRACTED_TEXT
        payload 'abcdefghi'
        payload_type Ddr::Batch::BatchObjectDatastream::PAYLOAD_TYPE_BYTES
      end

      factory :batch_object_add_extracted_text_datastream_file do
        name Ddr::Datastreams::EXTRACTED_TEXT
        payload File.join(Ddr::Batch::Engine.root, "spec", "fixtures", "ext_text.txt")
        payload_type Ddr::Batch::BatchObjectDatastream::PAYLOAD_TYPE_FILENAME
      end

      factory :batch_object_add_content_datastream do
        name Ddr::Datastreams::CONTENT
        payload File.join(Ddr::Batch::Engine.root.to_s, 'spec', 'fixtures', 'id001.tif')
        payload_type Ddr::Batch::BatchObjectDatastream::PAYLOAD_TYPE_FILENAME
        checksum "120ad0814f207c45d968b05f7435034ecfee8ac1a0958cd984a070dad31f66f3"
        checksum_type Ddr::Datastreams::CHECKSUM_TYPE_SHA256
      end

    end

    factory :batch_object_addupdate_datastream do
      operation Ddr::Batch::BatchObjectDatastream::OPERATION_ADDUPDATE

      # factory :batch_object_addupdate_desc_metadata_datastream_file do
      #   name Ddr::Datastreams::DESC_METADATA
      #   payload "/tmp/qdc-rdf.nt"
      #   payload_type Ddr::Batch::BatchObjectDatastream::PAYLOAD_TYPE_FILENAME
      # end

    end

  end

end
