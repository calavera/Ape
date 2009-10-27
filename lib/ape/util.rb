module Ape
  module Util
    def self.included(base)      
      base.extend ClassMethods  
      include InstanceMethods
    end

    def self.extended(base)
      base.extend InstanceMethods
      base.extend ClassMethods
    end
    
    module InstanceMethods
=begin
    Get a resource, optionally check its content-type
=end
    def check_resource(uri, name, content_type = nil, report = true)
      resource = Getter.new(uri, @authent)

      # * Check the URI
      if resource.last_error
        reporter.error(self, "Unacceptable #{name} URI: " + resource.last_error, name) if report
        return nil
      end

      # * Get it, make sure it has the right content-type
      worked = resource.get(content_type)
      reporter.save_dialog(name, resource) if report

      reporter.security_warning(self) if (resource.security_warning && report)

      if !worked
        # oops, couldn't even get get it
        reporter.error(self, "#{name} failed: " + resource.last_error, name) if report
        return nil

      elsif resource.last_error
        # oops, media-type problem
        reporter.error(self, "#{name}: #{resource.last_error}", name) if report
      else
        # resource fetched and is of right type
        reporter.success(self, "#{name}: it exists and is served properly.", name) if report
      end

      return resource
    end
  end
    
    module ClassMethods
=begin
  Resolve extensions into the lib directory or into the ape home directory. These extensions could be validators,
resolvers or samples.
=end    
      def resolve_plugin(key, dir, suffix, drop_underlines = false)
        [File.dirname(__FILE__), ::Ape.home].each do |path|
          Dir[File.join(path, "#{dir}/*.rb")].each do |file|
            require file
            plugin_name = file.gsub(/(.+\/#{dir}\/)(.+)(_#{suffix}.rb)/, '\2')
            plugin_name.gsub!(/_/, '') if drop_underlines
            plugin_class = file.gsub(/(.+\/#{dir}\/)(.+)(.rb)/, '\2').gsub(/(^|_)(.)/) { $2.upcase }

            if (key.to_s.strip.downcase.include?(plugin_name))
              return eval("#{plugin_class}.new", binding, __FILE__, __LINE__)            
            end
          end
        end
        return nil
      end
    end
  end
end
