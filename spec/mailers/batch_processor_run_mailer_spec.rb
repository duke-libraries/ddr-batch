require "rails_helper"

module Ddr::Batch

  describe BatchProcessorRunMailer, type: :mailer, batch: true do
    let(:user) { FactoryGirl.create(:user) }
    let(:batch) { Ddr::Batch::Batch.new(id: 54,
                                        user_id: user.id,
                                        status: Batch::STATUS_FINISHED,
                                        outcome: Batch::OUTCOME_SUCCESS,
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
      allow(File).to receive(:read).with(logfile_path) { 'Ingested TestModel' }
    end

    it "should send a notification" do
      Ddr::Batch::BatchProcessorRunMailer.send_notification(batch).deliver!
      expect(ActionMailer::Base.deliveries).not_to be_empty
      email = ActionMailer::Base.deliveries.first
      expect(email.to).to eq([user.email])
      expect(email.subject).to include("Batch Processor Run #{batch.status} #{batch.outcome}")
      expect(email.parts.first.to_s).to include("Ingested TestModel")
      expect(email.parts.second.to_s).to include("Objects in batch: #{batch.batch_objects.count}")
      expect(email.parts.second.to_s).to include(Batch::OUTCOME_SUCCESS)
    end
  end

end
