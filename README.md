# Get-PendingRenewals
Simple script for MS partners to scrape all of their delegated tenants for expiring subscriptions. The account used for authentication needs to be in your partner tenant and have access to DAP customer administration.

Does not filter out all "not of interest" SKUs, but filters out the 10k seat free SKUs (by excluding >5k seat subscriptions).

Needs some fiddling for running unattended, probably

Have not tested with GDAP/PIM.
