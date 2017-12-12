FactoryGirl.define do
  factory :batch, :class => Ddr::Batch::Batch do
    name "Batch"
    description "This is a batch of stuff to do."
    user { FactoryGirl.create(:user) }

    factory :collection_creating_ingest_batch do
      after(:create) do |batch, evaluator|
        # Collection
        coll = create(:collection_ingest_batch_object, pid: 'test:1', batch: batch)
        # Item 1
        item = create(:item_ingest_batch_object, pid: 'test:2', batch: batch)
        create(:batch_object_add_parent, object: coll.pid, batch_object: item)
        # Component for Item 1
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        # Item 2
        item = create(:item_ingest_batch_object, pid: 'test:3', batch: batch)
        create(:batch_object_add_parent, object: coll.pid, batch_object: item)
        # Components for Item 2
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        # Target
        create(:target_ingest_batch_object, batch: batch)
        # Attachment
        create(:attachment_ingest_batch_object, batch: batch)
      end
    end

    factory :item_adding_ingest_batch do
      after(:create) do |batch, evaluator|
        # Item 1
        item = create(:item_ingest_batch_object, pid: 'test:2', batch: batch)
        create(:batch_object_add_parent, object: 'test:1', batch_object: item)
        # Component for Item 1
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        # Item 2
        item = create(:item_ingest_batch_object, pid: 'test:3', batch: batch)
        create(:batch_object_add_parent, object: 'test:1', batch_object: item)
        # Components for Item 2
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        comp = create(:component_ingest_batch_object, batch: batch)
        create(:batch_object_add_parent, object: item.pid, batch_object: comp)
        # Target
        create(:target_ingest_batch_object, batch: batch)
        # Attachment
        create(:attachment_ingest_batch_object, batch: batch)
      end
    end

    factory :item_update_batch do
      after(:create) do |batch, evaluator|
        create(:update_batch_object, model: 'Item', batch: batch)
        create(:update_batch_object, model: 'Item', batch: batch)
        create(:update_batch_object, model: 'Item', batch: batch)
      end
    end

    factory :batch_with_basic_ingest_batch_objects do
      transient do
        object_count 3
      end
      after(:create) do |batch, evaluator|
        FactoryGirl.create_list(:basic_ingest_batch_object, evaluator.object_count, :batch => batch)
      end
    end

    factory :batch_with_generic_ingest_batch_objects do
      transient do
        object_count 3
      end
      after(:create) do |batch, evaluator|
        FactoryGirl.create_list(:generic_ingest_batch_object_with_attributes, evaluator.object_count, :batch => batch)
      end
    end

    factory :batch_with_basic_update_batch_object do
      after(:create) do |batch|
        FactoryGirl.create(:basic_update_batch_object, :batch => batch)
      end
    end

    factory :batch_with_basic_clear_attribute_batch_object do
      after(:create) do |batch|
        FactoryGirl.create(:basic_update_clear_attribute_batch_object, batch: batch)
      end
    end

    factory :batch_with_basic_clear_all_and_add_batch_object do
      after(:create) do |batch|
        FactoryGirl.create(:basic_clear_all_and_add_batch_object, :batch => batch)
      end
    end

  end
end
