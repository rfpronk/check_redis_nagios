#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'redis'

connectionOptions = { :host => "localhost", :port => 6379, :password => nil, :timeout => 5, :ssl => false, :ssl_params => {:ca_file => nil}}
sentinel = nil
desired_replica_count = 1

OptionParser.new do |opt|
  opt.banner = "Usage: #{$0} <options>"
  
  opt.on('-H', '--host [HOSTNAME]', 'Hostname (Default: "localhost")') { |o| connectionOptions[:host] = o if o }
  opt.on('-p', '--port [PORT]', 'Port (Default: "6379")') { |o| connectionOptions[:port] = o if o }
  opt.on('-P', '--password [PASSWORD]', 'Password (Default: blank)') { |o| connectionOptions[:password] = o if o }
  opt.on('-S', '--sentinel [MASTER]', 'Connect to Sentinel and ask for MASTER') { |o| sentinel = o if o }
  opt.on('-T', '--tls', 'Connect to Redis using SSL/TLS') { |o| connectionOptions[:ssl] = true if o }
  opt.on('-C', '--ca [CA_FILE]', 'Verify servers against given CA when using -T (use system default trusted certs when not specified)') { |o| connectionOptions[:ssl_params][:ca_file] = o if o }
  opt.on('-r', '--replicas [COUNT]', 'Minimum connected replicas for a master (Default: 1)') { |o| desired_replica_count = o.to_i if o }
  opt.on_tail("-h", "--help", "Show this message") do
    puts opt
    exit 0
  end
end.parse!

status_line = ""
status_code = 0
error_msg = ""

begin
  # Connecting to standalone Redis instance or through Sentinel?
  if sentinel
    # TODO
    @redis = Redis.new(connectionOptions)
  else
    @redis = Redis.new(connectionOptions)
  end
  ping = @redis.ping
  if ping != "PONG"
      status_line = "Redis didn't respond to PING"
      status_code = 2
  else 
    info = @redis.info

    status_line = "Redis version: " + info["redis_version"] + ", role: " + info["role"].sub("slave", "replica") + ", connected clients: " + info["connected_clients"] + ", used memory: " + info["used_memory_human"]  
    status_code = 0

    # Detect role
    if info["role"] == "master"
      status_line += ", connected replicas: " + info["connected_slaves"]
      if info["connected_slaves"].to_i < desired_replica_count
        status_code = 1
        error_msg = "Not enough connected replicas: " + info["connected_slaves"]
      end
    elsif info["role"] == "slave"
      if info["master_link_status"] != "up"
        status_code = 2
        error_msg = "Not connected to master, received last data " + info["master_last_io_seconds_ago"] + "s ago"
      end
      if info["master_last_io_seconds_ago"].to_i > 5
        status_code = 1
        error_msg = "Master didn't communicate in " + info["master_last_io_seconds_ago"] + "s"
      end
    end
  end
rescue Errno::ECONNREFUSED => e
  status_code = 2
  error_msg = e.message
rescue Errno::ENETUNREACH => e
  status_code = 2
  error_msg = e.message
rescue Errno::EHOSTUNREACH => e
  status_code = 2
  error_msg = e.message
rescue Errno::EACCES => e
  status_code = 2
  error_msg = e.message
rescue Redis::CommandError => e
  status_code = 2
  error_msg = e.message
rescue => e
  status_code = 3
  error_msg = e.message
end

case status_code
when 0
  puts "OK: " + status_line
when 1
  puts "WARNING: " + error_msg + " | " + status_line
when 2
  puts "CRITICAL: " + error_msg + " | " + status_line
when 3
  puts "UNKNOWN: " + error_msg + " | " + status_line
end

exit status_code
