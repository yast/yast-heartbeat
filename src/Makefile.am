# Makefile.am for heartbeat/src

yncludedir = @yncludedir@/heartbeat

client_DATA =			\
	heartbeat.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	node_conf.ycp		\
	auth_conf.ycp		\
	stonith_conf.ycp	\
	resources_conf.ycp	\
	startup_conf.ycp	\
	media_conf.ycp		\
	ipfail_conf.ycp		\
	timeouts_conf.ycp	\
	common.ycp


desktop_DATA =			\
	heartbeat.desktop

module_DATA =			\
	Heartbeat.ycp

ycpchook = heartbeat

heartbeat:
	ln -s . heartbeat

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
