module Ape
  module ValidatorDsl
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def enabled
        define_method('enabled?') do
          return true
        end
      end
      
      def disabled
        define_method('enabled?') do
          return false
        end
      end

      def deterministic
        define_method('deterministic?') do
          return true
        end
      end
      
      def nondeterministic
        define_method('deterministic?') do
          return false
        end
      end
      
      def requires_presence_of(*args)
        define_method('manifest') do
          return args
        end
      end
    end
    
  end
end