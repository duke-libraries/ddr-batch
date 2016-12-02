##
## Subscriptions to ActiveSupport::Notifications instrumentation events
##

# Batch Processing events
ActiveSupport::Notifications.subscribe('started.batch.batch.ddr', Ddr::Batch::MonitorBatchStarted)
ActiveSupport::Notifications.subscribe('handled.batchobject.batch.ddr', Ddr::Batch::MonitorBatchObjectHandled)
ActiveSupport::Notifications.subscribe('finished.batch.batch.ddr', Ddr::Batch::MonitorBatchFinished)

