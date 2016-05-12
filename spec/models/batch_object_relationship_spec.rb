require 'rails_helper'

module Ddr::Batch

  RSpec.describe BatchObjectRelationship, type: :model do

    subject { described_class.new }

    let(:batch) { Batch.create }
    let(:parent_batch_object) { BatchObject.new(id: 7) }
    let(:batch_object) { BatchObject.new(model: 'TestChild') }
    let(:repo_object) { double(id: 'test-123456') }

    before do
      parent_batch_object.batch = batch
      parent_batch_object.save!
      batch_object.batch = batch
      batch_object.save!
      subject.batch_object = batch_object
    end

    describe 'custom validations' do
      describe 'record must be in batch' do
        context 'invalid' do
          before { subject.object = '4' }
          it 'should produce an appropriate validation error' do
            subject.record_must_be_in_batch
            expect(subject.errors[:object]).to include("#{subject.object} not found in this batch")
          end
        end
        context 'valid' do
          before { subject.object = parent_batch_object.id.to_s }
          it 'should not produce a validation error' do
            subject.record_must_be_in_batch
            expect(subject.errors[:object]).to be_empty
          end
        end
      end
      describe 'repo object must exist' do
        before { subject.object = repo_object.id }
        context 'invalid' do
          it 'should produce an appropriate validation error' do
            subject.repo_object_must_exist
            expect(subject.errors[:object]).to include("#{subject.object} not found in repository")
          end
        end
        context 'valid' do
          before { allow(ActiveFedora::Base).to receive(:find).with(repo_object.id) { repo_object } }
          it 'should not produce a validation error' do
            subject.repo_object_must_exist
            expect(subject.errors[:object]).to be_empty
          end
        end
      end
      describe 'relationship name must be valid' do
        context 'invalid' do
          before { subject.name = BatchObjectRelationship::RELATIONSHIP_ATTACHED_TO }
          it 'should produce an appropriate validation error' do
            subject.relationship_name_must_be_valid_for_model
            expect(subject.errors[:name]).to include("#{batch_object.model} does not define a(n) #{subject.name} relationship")
          end
        end
        context 'valid' do
          before { subject.name = BatchObjectRelationship::RELATIONSHIP_PARENT }
          it 'should not produce a validation error' do
            subject.relationship_name_must_be_valid_for_model
            expect(subject.errors[:name]).to be_empty
          end
        end
      end
      describe 'model of object must be correct for relationship' do
        let(:correct_model) { 'TestParent' }
        before do
          subject.name = BatchObjectRelationship::RELATIONSHIP_PARENT
        end
        context 'invalid' do
          context 'object is record ID' do
            before do
              subject.object_type = BatchObjectRelationship::OBJECT_TYPE_REC_ID
              subject.object = parent_batch_object.id.to_s
              parent_batch_object.model = 'NotParent'
              parent_batch_object.save!
            end
            it 'should produce an appropriate validation error' do
              subject.object_model_must_be_correct_for_relationship
              expect(subject.errors[:object]).to include("#{subject.name} relationship object #{subject.object} exists but is not a(n) #{correct_model}")
            end
          end
          context 'object is repo ID' do
            before do
              subject.object_type = BatchObjectRelationship::OBJECT_TYPE_REPO_ID
              subject.object = repo_object.id
              allow(ActiveFedora::Base).to receive(:find).with(repo_object.id) { repo_object }
              allow(repo_object).to receive(:class) { Attachment }
            end
            it 'should produce an appropriate validation error' do
              subject.object_model_must_be_correct_for_relationship
              expect(subject.errors[:object]).to include("#{subject.name} relationship object #{subject.object} exists but is not a(n) #{correct_model}")
            end
          end
        end
        context 'valid' do
          context 'object is record ID' do
            before do
              subject.object_type = BatchObjectRelationship::OBJECT_TYPE_REC_ID
              subject.object = parent_batch_object.id.to_s
              parent_batch_object.model = 'TestParent'
              parent_batch_object.save!
            end
            it 'should not produce a validation error' do
              subject.object_model_must_be_correct_for_relationship
              expect(subject.errors[:object]).to be_empty
            end
          end
          context 'object is repo ID' do
            before do
              subject.object_type = BatchObjectRelationship::OBJECT_TYPE_REPO_ID
              subject.object = repo_object.id
              allow(ActiveFedora::Base).to receive(:find).with(repo_object.id) { repo_object }
              allow(repo_object).to receive(:class) { TestParent }
            end
            it 'should not produce a validation error' do
              subject.object_model_must_be_correct_for_relationship
              expect(subject.errors[:object]).to be_empty
            end
          end
        end
      end
    end

  end

end