###########################################################################################################
module Synaptic4r

  #########################################################################################################
  class Request

    #......................................................................................................
    def http_request(args)
      to_message_class(meth).send(:response, args)
    end

    #......................................................................................................
    def to_message_class(meth)
      eval("#{meth.to_s.split('_').collect{|s| s.capitalize}.join}Messages")
    end

  ### Rest 
  end


### Rest 
end

#########################################################################################################
module HttpMessages

  
  ####---------------------------------------------------------------------------------------------------
  class Body

    #......................................................................................................
    attr_reader :body

    #......................................................................................................
    def initialize(args)
      @body = args
    end

  #### Result
  end

  ####---------------------------------------------------------------------------------------------------
  class Result

    #......................................................................................................
    attr_reader :headers, :net_http_res

    #......................................................................................................
    def initialize(args)
      @headers = args[:headers]
      @net_http_res = Body.new(args[:body])
    end

  #### Result
  end

### HttpMessages
end
