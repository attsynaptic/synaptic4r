############################################################################################################
module Synaptic4r
  
  ##########################################################################################################
  class Result

    #.......................................................................................................
    attr_reader :headers, :url, :http_request, :sign, :payload, :result

    #.......................................................................................................
    def initialize(args)
      @http_request = args[:http_request]
      @headers = args[:headers]
      @url = args[:url]
      @sign =  args[:sign]
      @payload = args[:payload]
      @result = {}
    end

    #.......................................................................................................
    def print
    end

    #.........................................................................................................
    def method_missing(meth, *args, &blk)
      if result.kind_of?(Hash) and result.keys.include?(meth)
        result[meth]
      else
        result.send(meth, *args, &blk)
      end
    end

    #.......................................................................................................
    def extract_header(args, header)
      headers = args[:result].headers[header]
      if headers
        headers.split(/,\s+/).map{|a| a.strip}.inject({}) do |r,a| 
          v = a.split('=')
          v << 'N/A' if v.length < 2
          r.update(v.first => v.last)
        end
      else
        {}
      end    
    end

    #.......................................................................................................
    def stringify_hash(h)
      h.inject(""){|r,(u,a)| r += "  #{u}=#{a}\n"}
    end
   

    #.......................................................................................................
    def stringify_array(a)
      a.split(/,\s+/).sort.inject(""){|s,t| s += "#{t}, "}.chomp(', ') if a
    end
   

  #Response
  end 

  ##########################################################################################################
  class StorageObject < Result
    
    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        location = args[:result].headers[:location]
        @result = {:oid =>      /\/rest\/objects\/(.*)/.match(location).captures.first,
                   :location => location,
                   :size =>     args[:result].headers[:x_emc_delta],
                   :date =>     args[:result].headers[:date]}
      end
    end

    #.......................................................................................................
    def print
      (oid.nil? ? '' : "OID:  #{oid}\n") + 
      (size.nil? ? '' : "size: #{size} bytes")
    end

  #Upload
  end 

  ##########################################################################################################
  class UserMetadata < Result
    
    #.......................................................................................................
    attr_reader :metadata, :listable_metadata

    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @metadata = extract_header(args, :x_emc_meta)
        @listable_metadata = extract_header(args, :x_emc_listable_meta)
      end
    end

    #.......................................................................................................
    def print
      unless @metadata.empty? and @listable_metadata.empty?
        (@metadata.empty? ? '' : "Not Listable Metadata\n#{stringify_hash(@metadata)}") +
          (@listable_metadata.empty? ? '' : "Listable Metadata\n#{stringify_hash(@listable_metadata)}")
      end
    end

  #UserMetadata
  end 


  ##########################################################################################################
  class SystemMetadata < Result
    
    #.......................................................................................................
    attr_reader :metadata

    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @metadata = extract_header(args, :x_emc_meta)
      end
    end

    #.......................................................................................................
    def print
      stringify_hash(@metadata)
    end

  #SystemMetadata
  end 


  ##########################################################################################################
  class Tags < Result
    
    #.......................................................................................................
    attr_reader :listable_tags

    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @listable_tags = args[:result].headers[:x_emc_listable_tags]
      end
    end

    #.......................................................................................................
    def print
      stringify_array(@listable_tags)
    end

  #Metadata
  end 

  ##########################################################################################################
  class Acl < Result
    
    #.......................................................................................................
    attr_reader :user_acl, :group_acl

    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @user_acl = extract_header(args, :x_emc_useracl)
        @group_acl = extract_header(args, :x_emc_groupacl)
      end
    end

    #.......................................................................................................
    def print
      "User ACL\n#{stringify_hash(@user_acl)}Group ACL\n#{stringify_hash(@group_acl)}"
    end

  #Acl
  end 

  ##########################################################################################################
  class Versions < Result
    
    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @versions =  REXML::Document.new(args[:result].net_http_res.body).root
      end
    end

    #.......................................................................................................
    def print
      poids = oids
      poids.inject("") {|r,o| r += "  #{o}\n"} unless poids.empty?
    end

    #.......................................................................................................
    def oids
      @versions.elements.to_a('ObjectID').map{|o| o.text}      
    end

  #Acl
  end 


  ##########################################################################################################
  class StorageObjectList < Result
    
    #.......................................................................................................
    def initialize(args)
      super
      if args[:result]
        @objs =  REXML::Document.new(args[:result].net_http_res.body).root
      end
     end

    #.......................................................................................................
    def print
      ols = objs
      oid = oids(ols)
      sys_meta = metadata(ols, 'SystemMetadataList')
      user_meta = metadata(ols, 'UserMetadataList', true)
      unless sys_meta.empty?
        fmt = "%-40s %-10s %-s\n"
        fmt % ['Metadata', 'Type', 'OID'] +
          sys_meta.inject("") do |r,e| 
            t = e['type']
            r += fmt % [user_meta.shift.keys.join(','), (t.eql?('regular') ? 'file' : t), e['objectid']]
          end
      else
        "OID\n" + oid.join("\n").chomp unless oid.empty?
      end
    end

    #.......................................................................................................
    def oids(ols)
      ols.map{|o| o.elements.to_a('ObjectID').first.text}   
    end

    #.......................................................................................................
    def metadata(ols, tag, is_listable=false)
      meta = ols.map{|o| o.elements.to_a(tag)}
      meta.map{|a| a.empty? ? nil : a.first.elements.to_a.inject({}) do |h,s| 
        a = extract_attrs(s, is_listable)
        a.nil? ? h : h.update(a)
      end}.compact
    end

    #.......................................................................................................
    def extract_attrs(a,is_listable)
      add_item = if is_listable
                   a.elements.to_a('Listable').first.text.eql?('true')
                 else; true; end
      add_item ? {a.elements.to_a('Name').first.text => a.elements.to_a('Value').first.text} : nil
    end

    #.......................................................................................................
    def objs
      @objs.nil? ? [] : @objs.elements.to_a('Object')    
    end

  #SorageObjectList
  end 

  ##########################################################################################################
  class Download < Result
    
    #.......................................................................................................
    def initialize(args)
      super   
      if args[:result]
        @body = args[:result].net_http_res.body
        @result[:content_type] = args[:result].headers[:content_type]
        if content_type.eql?('text/xml')
          @result[:directory] = directory_entries
        else
          @result[:file] = @body
        end
      end
    end

    #.......................................................................................................
    def print
      if content_type.eql?('text/xml')
        print_directory_entries
      else
        @body
      end
    end

    #.......................................................................................................
    def directory_entries
      REXML::Document.new(@body).root.elements.to_a.first.elements.to_a.map do |i|
        i.elements.inject(nil, {}){|h,e| h.update(e.name.downcase.to_sym => e.text)}
      end
    end

    #.......................................................................................................
    def print_directory_entries
      dir_list = directory_entries
      unless dir_list.empty?
        fmt = "%-30s %-10s %-s\n"
        fmt % ['Name', 'Type', 'OID'] +
        dir_list.inject("") do |r,e| 
          t = e[:filetype]
          r += fmt % [e[:filename], (t.eql?('regular') ? 'file' : t), e[:objectid]]
        end
      end
    end

    #.......................................................................................................
    def octet_stream
      @body
    end

  #RetrievedFile
  end 

  ##########################################################################################################
  class RequestError
    
    #.......................................................................................................
    def initialize(err)
      @err = REXML::Document.new(err.response.body).root
    end

   #.......................................................................................................
    def code
      @err.elements.to_a('Code').first.text if @err.elements.to_a('Code').first    
    end

    #.......................................................................................................
    def message
      @err.elements.to_a('Message').first.text if @err.elements.to_a('Message').first     
    end

    #.......................................................................................................
    def print 
      @err.nil? ? '' : "#{code}: #{message}"
    end

  #RequestError 
  end 


  ##########################################################################################################
  class ShareableUrl < Result
    
    #.......................................................................................................
    def initialize(args)
      super
      @url = args[:result]
    end

    #.......................................................................................................
    def print
      @url
    end

  #SystemMetadata
  end 

#Synaptic4r
end
