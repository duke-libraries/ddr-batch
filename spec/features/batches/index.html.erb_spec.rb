require 'rails_helper'

describe "ddr/batch/batches/index.html.erb", :type => :feature do
  context "batches" do
    let(:batch) { FactoryGirl.create(:batch_with_basic_ingest_batch_objects) }
    let(:other_user) { FactoryGirl.create(:user) }
    context "pending batches" do
      let(:tab_id) { '#tab_pending_batches' }
      context "user has no pending batches" do
        before do
          login_as other_user
          visit ddr_batch.batches_path
        end
        it "should display an appropriate message" do
          within tab_id do
            expect(page).to have_text(I18n.t('ddr.batch.no_batches', :type => I18n.t('ddr.batch.web.tabs.pending_batches.label')))
          end
        end
      end
      context "user has some pending batches" do
        before do
          login_as batch.user
          visit ddr_batch.batches_path
        end
        it "should list the batch on the pending tab" do
          within tab_id do
            expect(page).to have_link(batch.id, :href => ddr_batch.batch_path(batch))
          end
        end
      end
      context "new batch" do
        context "new" do
          before do
            login_as batch.user
            visit ddr_batch.batches_path
          end
          it "should not have a link to process the batch" do
            within tab_id do
              expect(page).to_not have_link(I18n.t('ddr.batch.web.action_names.procezz'), :href => ddr_batch.procezz_batch_path(batch))
            end
          end
        end
      end
      context "ready to process batch" do
        context "ready" do
          before do
            batch.status = Ddr::Batch::Batch::STATUS_READY
            batch.save
            login_as batch.user
            visit ddr_batch.batches_path
          end
          it "should have a link to process the batch" do
            within tab_id do
              expect(page).to have_link(I18n.t('ddr.batch.web.action_names.procezz'), :href => ddr_batch.procezz_batch_path(batch))
            end
          end
        end
      end
      context "validate action" do
        before { login_as batch.user }
        context "validated and valid" do
          before do
            batch.status = Ddr::Batch::Batch::STATUS_VALIDATED
            batch.save
            visit ddr_batch.batches_path
          end
          it "should have a link to process the batch" do
            within tab_id do
              expect(page).to have_link(I18n.t('ddr.batch.web.action_names.procezz'), :href => ddr_batch.procezz_batch_path(batch))
            end
          end
        end
        context "validated and invalid" do
          before do
            batch.status = Ddr::Batch::Batch::STATUS_INVALID
            batch.save
            visit ddr_batch.batches_path
          end
          it "should have a link to retry the batch" do
            within tab_id do
              expect(page).to have_link(I18n.t('ddr.batch.web.action_names.retry'), :href => ddr_batch.procezz_batch_path(batch))
            end
          end
        end
      end
    end
    context "finished batches" do
      let(:tab_id) { '#tab_finished_batches' }
      context "user has no finished batches" do
        before do
          login_as other_user
          visit ddr_batch.batches_path
        end
        it "should display an appropriate message" do
          within tab_id do
            expect(page).to have_text(I18n.t('ddr.batch.no_batches', :type => I18n.t('ddr.batch.web.tabs.finished_batches.label')))
          end
        end
      end
      context "user has some finished batches" do
        before do
          batch.status = Ddr::Batch::Batch::STATUS_FINISHED
          batch.save
          login_as batch.user
          visit ddr_batch.batches_path
        end
        it "should list the batch on the already run tab" do
          within tab_id do
            expect(page).to have_link(batch.id, :href => ddr_batch.batch_path(batch))
          end
        end
      end
    end
    context "deleting batches" do
      before { login_as batch.user }
      context "no delete-able batches" do
        [ Ddr::Batch::Batch::STATUS_QUEUED, Ddr::Batch::Batch::STATUS_RUNNING,
          Ddr::Batch::Batch::STATUS_FINISHED, Ddr::Batch::Batch::STATUS_INTERRUPTED,
          Ddr::Batch::Batch::STATUS_RESTARTABLE ].each do |status|
            context "status #{status}" do
              before do
                batch.status = status
                batch.save
                visit ddr_batch.batches_path
              end
              it "should not have a link to delete the batch" do
                expect(page).to_not have_link("batch_delete_#{batch.id}")
              end
            end
          end
      end
    end
  end
end