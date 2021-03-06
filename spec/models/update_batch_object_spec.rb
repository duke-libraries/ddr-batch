require 'rails_helper'

module Ddr::Batch

  shared_examples "a valid update object" do
    it "should be valid" do
      expect(object.validate).to be_empty
    end
  end

  shared_examples "an invalid update object" do
    it "should not be valid" do
      expect(object.validate).to include(error_message)
    end
  end

  shared_examples "a loggable event has occurred" do
    it "should log the event" do
      expect(repo_object.update_events.last.comment).to eq("Updated by batch process (Batch #{object.batch.id}, BatchObject #{object.id})")
    end
  end

  describe UpdateBatchObject, type: :model, batch: true do

    let(:object) { batch.batch_objects.first }

    # before { allow(File).to receive(:readable?).with("/tmp/qdc-rdf.nt").and_return(true) }

    context "validate", validation: true do
      let(:batch) { FactoryGirl.create(:batch_with_basic_update_batch_object) }
      context "valid object" do
        let(:repo_object) { TestModel.new(:pid => object.pid) }
        before do
          repo_object.roles.grant({ type: 'MetadataEditor', agent: batch.user.user_key, scope: 'resource' })
          repo_object.save
        end
        context "generic object" do
          it_behaves_like "a valid update object"
        end
        context "generic object without a model attribute" do
          before { object.model = nil }
          it_behaves_like "a valid update object"
        end
      end
      context "invalid object" do
        let(:error_prefix) { "#{object.identifier}:"}
        context "missing pid" do
          let(:error_message) { "#{error_prefix} PID required for UPDATE operation" }
          before do
            object.pid = nil
            object.save!
          end
          it_behaves_like "an invalid update object"
        end
        context "pid not found in repository" do
          let(:error_message) { "#{error_prefix} PID #{object.pid} not found in repository" }
          it_behaves_like "an invalid update object"
        end
        context "batch user not permitted to edit repository object" do
          let!(:repo_object) { TestModel.create(:pid => object.pid) }
          let(:error_message) { "#{error_prefix} #{batch.user.user_key} not permitted to edit #{object.pid}" }
          it_behaves_like "an invalid update object"
        end
      end
    end

    context "update" do
      let(:repo_object) { TestModel.create(pid: object.pid, title: [ "Test Model Title" ], identifier: [ "id1", "id2" ]) }
      before do
        batch.user.can :edit, repo_object
        object.process(batch.user)
        repo_object.reload
      end
      context "attributes" do
        context "add" do
          let(:batch) { FactoryGirl.create(:batch_with_basic_update_batch_object) }
          it_behaves_like "a loggable event has occurred"
          it "should add the attribute value to the repository object" do
            expect(repo_object.title).to eq( [ 'Test Model Title', 'Test Object Title' ] )
          end
        end
        context "clear" do
          let(:batch) { FactoryGirl.create(:batch_with_basic_clear_attribute_batch_object) }
          it_behaves_like "a loggable event has occurred"
          it "should clear the attribute in the repository object" do
            expect(repo_object.title).to be_empty
          end
        end
        # Can't really test just clearing all attributes because can't save datastream with no content
        context "clear all and add" do
          let(:batch) { FactoryGirl.create(:batch_with_basic_clear_all_and_add_batch_object) }
          it_behaves_like "a loggable event has occurred"
          it "should clear the existing attributes from the repository object and add an attribute value" do
            expect(repo_object.title).to eq( [ 'Test Object Title' ] )
            expect(repo_object.identifier).to be_empty
          end
        end
      end
      context "verifications" do
        let(:batch) { FactoryGirl.create(:batch_with_basic_update_batch_object) }
        before do
          object.process(batch.user)
          repo_object.reload
        end
        context "no verification failure" do
          let(:repo_object) { TestModelOmnibus.create(pid: object.pid, title: [ "Test Model Title" ], identifier: [ "id1", "id2" ]) }
          it "logs an appropriate validation event" do
            validation_events = repo_object.events.where(type: Ddr::Events::ValidationEvent)
            expect(validation_events).to_not be_empty
            expect(validation_events.first.outcome).to eq(Ddr::Events::Event::SUCCESS)
            expect(validation_events.first.detail).to include('PASS')
            expect(validation_events.first.detail).to_not include('FAIL')
          end
        end
        context "verification failure" do
          it "logs an appropriate validation event" do
            validation_events = repo_object.events.where(type: Ddr::Events::ValidationEvent)
            expect(validation_events).to_not be_empty
            expect(validation_events.first.outcome).to eq(Ddr::Events::Event::FAILURE)
            expect(validation_events.first.detail).to include('FAIL')
          end
        end
      end
    end
  end
end
