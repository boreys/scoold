# Class: scoold
#
# This module manages scoold.com servers
#
class scoold {
	# ----------------- EDIT HERE ---------------------#	
	$inproduction = false
	$defuser = "ubuntu"
	$release = "natty"
	
	#--- AUTO UPDATED - CHANGES WILL BE OVERWRITTEN ---#
	$nodename = "web2"
	$dbseeds = "10.234.157.237,10.235.6.253"
	$dbhosts = "10.234.157.237,10.235.6.253,10.228.139.81"
	#--------------------------------------------------#	
	
	#### Cassandra ####	
	$casver = "0.8.5"
	$caslink = "http://www.eu.apache.org/dist/cassandra/${casver}/apache-cassandra-${casver}-bin.tar.gz"
	$jnalink = "http://java.net/projects/jna/sources/svn/content/trunk/jnalib/dist/jna.jar"
	$dbheapsize = "7G" # memory of m1.large
	$dbheapnew = "200M"
	$dbcluster = "scoold"
	$dbupgrade = true
	
	#### Glassfish ####
	$gflink = "http://dlc.sun.com.edgesuite.net/glassfish/3.1.1/release/glassfish-3.1.1.zip"	
	$gfcluster = "scoold" 
		 
	#### Elasticsearch ####
	$esmaster = true
	$esver = "0.17.6"
	$eslink = "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-${esver}.zip"
	$esriverlink = "https://s3-eu-west-1.amazonaws.com/com.scoold.files/river-amazonsqs.zip"
	$esguilink = "https://github.com/mobz/elasticsearch-head/zipball/master"
	$esport = 9200
	$esheapsize = "1200M"
	$esheapdev = "200M"
	$esindex = "scoold"
	if inproduction == false {		
		$esheapsize = $esheapdev	
	}
	# --------------------------------------------#
	
	Package { ensure => latest}
	User { ensure => present }
	Group { ensure => present }
	File { ensure => present }
	Service { ensure => running }
	Exec { path => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"] }
    stage { "last": require => Stage["main"] }	
	
	case $nodename {
      /^web(\d*)$/: { 
      	class { "scoold::glassfish": stage => "main" }
    	class { "scoold::monit": stage => "last", type => "glassfish" }  	 
      } 
      /^db(\d*)$/: { 
      	class { "scoold::cassandra": stage => "main" }
    	class { "scoold::monit": stage => "last", type => "cassandra" } 
      } 
      /^search(\d*)$/: { 
      	class { "scoold::elasticsearch": stage => "main" }
    	class { "scoold::monit": stage => "last", type => "elasticsearch" } 
      }  
    }   
    	
	file { "/etc/sudoers":
        owner => root,
        group => root,
        mode  => 440,
    }
	
	define line ($file, $line, $ensure = 'present') {
		case $ensure {
			default: {
				err("unknown ensure value ${ensure}")
			}
			present: {
				exec{
					"/bin/echo '${line}' >> '${file}'":
						unless => "/bin/grep -qFx '${line}' '${file}'"
				}
			}
			absent: {
				exec{
					"/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
						onlyif => "/bin/grep -qFx '${line}' '${file}'"
				}
			}
		}
	}		
}
