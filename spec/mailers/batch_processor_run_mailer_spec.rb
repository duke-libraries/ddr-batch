require "rails_helper"

module Ddr::Batch

  describe BatchProcessorRunMailer, type: :mailer, batch: true do
    let(:user) { FactoryGirl.create(:user) }
    let(:collection_title) { 'Test & Drive Collection: An Auto Deposit' }
    let(:munged_collection_title) { 'Test_Drive_Collection_An_Auto_Deposit' }
    let(:batch) { Ddr::Batch::Batch.new(id: 54,
                                        user_id: user.id,
                                        status: Batch::STATUS_FINISHED,
                                        outcome: Batch::OUTCOME_SUCCESS,
                                        collection_title: collection_title,
                                        logfile_file_name: 'test.txt'
                                       )
                }
    let(:logfile_path) { File.join(Paperclip::Interpolations.rails_root(batch.logfile, 'original'),
                                   'public',
                                   'system',
                                   Paperclip::Interpolations.class(batch.logfile, 'original'),
                                   Paperclip::Interpolations.attachment(batch.logfile, 'original'),
                                   Paperclip::Interpolations.id_partition(batch.logfile, 'original'),
                                   Paperclip::Interpolations.style(batch.logfile, 'original'),
                                   Paperclip::Interpolations.filename(batch.logfile, 'original')
                                  )
                       }

    before do
      allow(File).to receive(:read).with(logfile_path) { "Collection: #{collection_title}\n\nIngested TestModel" }
    end

    it "should send a notification" do
      Ddr::Batch::BatchProcessorRunMailer.send_notification(batch).deliver_now!
      expect(ActionMailer::Base.deliveries).not_to be_empty
      email = ActionMailer::Base.deliveries.first
      expect(email.to).to eq([user.email])
      expect(email.subject).to include("Batch Processor Run #{batch.status} #{batch.outcome} - #{collection_title}")
      expect(email.to_s).to include(collection_title)
      expect(email.to_s).to include("Objects in batch: #{batch.batch_objects.count}")
      expect(email.to_s).to include(Batch::OUTCOME_SUCCESS)
      expect(email.attachments.first.filename).to eq("details_#{munged_collection_title}.txt")
      expect(email.attachments.first.to_s).to match(/^Collection: #{collection_title}.*/)
      expect(email.attachments.first.to_s).to include("Ingested TestModel")
    end
  end

end
