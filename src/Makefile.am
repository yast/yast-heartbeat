# Sources for heartbeat

module_DATA = \
  modules/Heartbeat.rb

client_DATA = \
  clients/heartbeat.rb

yncludedir = @yncludedir@/heartbeat
ynclude_DATA = \
  include/heartbeat/media_conf.rb \
  include/heartbeat/resources_conf.rb \
  include/heartbeat/auth_conf.rb \
  include/heartbeat/wizards.rb \
  include/heartbeat/ipfail_conf.rb \
  include/heartbeat/node_conf.rb \
  include/heartbeat/commandline.rb \
  include/heartbeat/stonith_conf.rb \
  include/heartbeat/startup_conf.rb \
  include/heartbeat/common.rb \
  include/heartbeat/timeouts_conf.rb \
  include/heartbeat/dialogs.rb \
  include/heartbeat/helps.rb

scrconf_DATA = \
  scrconf/etc_ha_d_ha_cf.scr \
  scrconf/etc_ha_d_authkeys.scr \
  scrconf/etc_ha_d_haresources.scr

desktop_DATA = \
  desktop/heartbeat.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common