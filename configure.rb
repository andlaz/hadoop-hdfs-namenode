require "thor"
require "erb"
require "fileutils"

class Configure < Thor
 
  # ...
  def self.exit_on_failure?
    true
  end 
  
  class << self
    def options(options={})
      
      options.each do |option_name, option_settings|
        option option_name, option_settings  
      end
  
    end
  end
  
  module ERBRenderer
    
    def render_from(template_path)
      ERB.new(File.read(template_path), 0, '<>').result binding
    end
    
  end  
  
  class HDFSConfiguration
    include ERBRenderer
    
     attr_accessor :tmp_dir,
      :fs_host,
      :fs_port,
      :default_fs
         
  end
  
  class HDFSNameNodeConfiguration < HDFSConfiguration
    
    attr_accessor :name_dir,
      :hdfs_replication_factor,
      :hdfs_block_size
    
  end
  
  class HDFSSecondaryNameNodeConfiguration < HDFSConfiguration
    
    attr_accessor :secondary_name_dir,
      :name_web_ui_port

  end
  
  @@hdfs_options = {
    :tmp_dir => { :default => "/var/lib/hdfs/tmp", :desc => "HDFS temp dir" },
    :fs_host => { :required => true, :desc => "Host to listen on for HDFS clients" },
    :fs_port => { :default => 8020 }

  }
  
  options @@hdfs_options
  option :format, :type => "boolean", :default => false, :desc => "Format the distributed file system ( use with care )"
  option :name_dir, :default => "/var/lib/hdfs/name", :desc => "Directory to store primary name ( dfs ) data"
  option :hdfs_replication_factor, :default => 3, :desc => "HDFS replication factor"
  option :hdfs_block_size, :default => "128m", :desc => "HDFS block size"
  desc "namenode", "Configure the HDFS primary Name Node"
  def namenode
    
    configuration = HDFSNameNodeConfiguration.new
    configuration.tmp_dir = options[:tmp_dir]
    configuration.fs_host = options[:fs_host]
    configuration.default_fs = "hdfs://#{options[:fs_host]}:#{options[:fs_port]}"
    
    configuration.name_dir = options[:name_dir]
    configuration.hdfs_replication_factor = options[:hdfs_replication_factor]
    configuration.hdfs_block_size = options[:hdfs_block_size]


    File.write '/etc/hadoop/hdfs-site.xml',
      configuration.render_from('/etc/hadoop/hdfs-site.xml.namenode.erb')

    File.write '/etc/hadoop/core-site.xml',
      configuration.render_from('/etc/hadoop/core-site.xml.erb')
    
    File.write '/etc/supervisor/conf.d/namenode.conf',
      configuration.render_from('/etc/supervisor/conf.d/namenode.conf.erb')
    
    (FileUtils::mkdir_p options[:tmp_dir]; `chown -R hadoop #{options[:tmp_dir]}`) unless File.exists? options[:tmp_dir]
    FileUtils::mkdir_p options[:name_dir] unless File.exists? options[:name_dir]
    
    (`hadoop namenode -format`; `chown -R hadoop #{options[:name_dir]}`) if (options[:format])
    
  end
  
  options @@hdfs_options
  option :name_web_ui_port, :default => 50070, :desc => "HDFS primary Name Node Web UI port"
  option :secondary_name_dir, :default => "/var/lib/hdfs/namesecondary", :desc => "Directory to store secondary name ( dfs ) data"
  desc "namesecondary", "Configure the HDFS secondary Name Node"
  def namenodesecondary
    
    configuration = HDFSSecondaryNameNodeConfiguration.new
    configuration.tmp_dir = options[:tmp_dir]
    configuration.fs_host = options[:fs_host]
    configuration.fs_port = options[:fs_port]
    configuration.name_web_ui_port = options[:name_web_ui_port]
    configuration.default_fs = "hdfs://#{options[:fs_host]}:#{options[:fs_port]}"
      
    configuration.secondary_name_dir = options[:secondary_name_dir]

    File.write '/etc/hadoop/hdfs-site.xml',
      configuration.render_from('/etc/hadoop/hdfs-site.xml.namenode.secondary.erb')

    File.write '/etc/supervisor/conf.d/namenode.secondary.conf',
      configuration.render_from('/etc/supervisor/conf.d/namenode.secondary.conf.erb')
    
    (FileUtils::mkdir_p options[:tmp_dir]; `chown -R hadoop #{options[:tmp_dir]}`) unless File.exists? options[:tmp_dir]
    (FileUtils::mkdir_p options[:secondary_name_dir]; `chown -R hadoop #{options[:secondary_name_dir]}`) unless File.exists? options[:secondary_name_dir]    
    
  end
  
end

Configure.start(ARGV)