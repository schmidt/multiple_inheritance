#   Multiple Inheritance
#
#   Copyright (C) 2005 Maurice Codik - maurice.codik@gmail.com
#   Copyright (C) 2007 Gregor Schmidt - gregor@schmidtwisser.de 
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to 
#   deal in the Software without restriction, including without limitation the 
#   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or 
#   sell copies of the Software, and to permit persons to whom the Software is 
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in 
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#   IN THE SOFTWARE.

#   Changelog
#   0.1.5
#    - added `method_added` callback to superclasses to ensure the correct 
#      handling of open classes
#    - added caching for class lookup
#   0.1.4
#    - added caching of created mi classes
#    - changed api - `Multiple( A, B )` is now `MultipleInheritance[ A, B ]`
#    - everything resides within the module now so the global namespace 
#      is not poisoned anymore
#   0.1.3
#    - added support for blocks 
#   0.1.2
#    - added naive support for instance variables
#   0.1.1
#    - moved Multiple to module Kernel - so it's included in the class hierarchy

module MultipleInheritance 
  CLASSES = {}

  class << self
    def []( *superklasses )
      CLASSES[ superklasses ] ||= create_mi_class_for( superklasses )
    end
    
    def create_mi_class_for( superklasses )
      c = Class.new do

        attr_accessor :_parentinstances
        attr_accessor :_lookup_cache
        
        def initialize( *arguments, &block )
        # initialize each parent class
          self._parentinstances = self.class.superclasses.collect do |klass|
        # note: the constructors better be compatible, otherwise this will error
            klass.new( *arguments, &block )
          end
          self._lookup_cache = {}
        end
        
        def parent_class_for_instance_method( method_name_sym, if_nil = nil )
          self.class.parent_class_for_instance_method( method_name_sym, if_nil )
        end


        def parent_instance_for_instance_method( method_name_sym, if_nil = nil )
          parent_class = parent_class_for_instance_method( method_name_sym )
          ( _lookup_cache[parent_class] ||= 
                parent_instance_for_class( parent_class ) ) || if_nil
        end
        
        def parent_instance_for_class( klass )
          _parentinstances.find do | parent |
            parent.kind_of?( klass )
          end
        end

        def copy_class_variables( from, to )
          from.class_variables.each do | class_var |
            to.class_variable_set( class_var, 
                from.class_variable_get( class_var ) )
          end
        end
          
        def copy_class_variables_to_parent( parent_class )
          copy_class_variables( self.class, parent_class )
        end

        def copy_class_variables_from_parent( parent_class )
          copy_class_variables( parent_class, self.class )
        end
        
        def copy_instance_variables( from, to )
          from.instance_variables.each do | inst_var |
            to.instance_variable_set( inst_var, 
                from.instance_variable_get( inst_var ) )
          end
        end
        
        def copy_instance_variables_to_parent( parent_instance )
          copy_instance_variables( self, parent_instance )
        end

        def copy_instance_variables_from_parent( parent_instance )
          copy_instance_variables( parent_instance, self )
        end
   
        def parent_call( parent_instance, &block )
          copy_class_variables_to_parent( parent_instance.class )
          copy_instance_variables_to_parent( parent_instance )
          value = block.call
          copy_instance_variables_from_parent( parent_instance )
          copy_class_variables_from_parent( parent_instance.class )
          value
        end
        
        def send( method_name, *arguments, &block )
          if parent_instance = parent_instance_for_instance_method( 
                                                                method_name ) 
            parent_call( parent_instance ) do 
              parent_instance.send( method_name, *arguments, &block )
            end
          else
            method_missing( method_name, *arguments, &block )
          end
        end

        def method_missing( method_name, *arguments, &block )
          parent_instance = parent_instance_for_instance_method( 
                :method_missing, _parentinstances.first )
          parent_call( parent_instance ) do 
            parent_instance.method_missing( method_name , *arguments, &block )
          end
        end

        def respond_to?( meth )
          if _parentinstances.find { |p| p.respond_to? meth } 
            true
          else
            super
          end
        end

        def kind_of?( klass )
          klass == self.class or self.class.ancestors.include?( klass )
        end

        class << self
          attr_reader :_parentklasses
          protected :_parentklasses

          attr_accessor :_lookup_cache
          
          def to_s
            if _parentklasses 
              "MultipleInheritance[ " + superclasses.join( ", " ) + " ]"
            else
              super
            end
          end
          
          def superclasses
            _parentklasses || superclass._parentklasses
          end
          
          def ancestors
            superclasses.collect { | klass |
              klass.ancestors
            }.flatten.reverse.uniq.reverse
          end

          def inherited( subklass )
            superclasses.each do | klass | 
              klass.class_eval do
                inherited( subklass )
              end
            end
            super
          end

          def parent_class_for_instance_method( method_name_sym, if_nil = nil )
            ( superclass._lookup_cache[:instance_methods][method_name_sym] ||= 
              _parent_class_for_instance_method( method_name_sym ) ) || if_nil
          end
          
          def _parent_class_for_instance_method( method_name_sym )
            method_name = method_name_sym.to_s
            ancestors.find do | ancestor |
              ancestor.public_instance_methods( false ).include?( 
                                                              method_name ) or
              ancestor.protected_instance_methods( false ).include?( 
                                                              method_name ) or
              ancestor.private_instance_methods( false ).include?( method_name )
            end
          end
          
          def parent_class_for_class_method( method_name_sym, if_nil = nil )
            ( superclass._lookup_cache[:class_methods][method_name_sym] ||= 
              _parent_class_for_class_method( method_name_sym ) ) || if_nil
          end

          def _parent_class_for_class_method( method_name_sym )
            method_name = method_name_sym.to_s
            ancestors.find do | ancestor |
              ancestor.public_methods( false ).include?( method_name ) or
              ancestor.protected_methods( false ).include?( method_name ) or
              ancestor.private_methods( false ).include?( method_name )
            end
          end

          def const_missing( constant_name )
            if right_klass = superclasses.find do | superklass |
                superklass.constants.include?( constant_name.to_s )
              end
              right_klass.const_get( constant_name )
            else
              parent_class_for_class_method( 
                  :const_missing ).const_missing( constant_name )
            end
          end

          def invalidate_caches
            self._lookup_cache = {
                :instance_methods => {},
                :class_methods => {}
              }
          end

          def define_blank_method( method_name, modifier = :public )
            invalidate_caches
            unless instance_methods( false ).include? method_name.to_s
              class_eval %Q{
                def #{method_name}( *arguments, &block )
                  send( :#{method_name}, *arguments, &block )
                end
              }
              class_eval do
                send( modifier, method_name )
              end unless modifier.nil? or modifier == :public
            end
          end
        end
      end
      
      # we need to save the parent classes so they can be initialized when 
      # our class is initialized
      c.class_eval do 
        _lookup_cache = { 
            :class_methods => {}, 
            :instance_methods => {} } 
        @_parentklasses = superklasses 
      end

      # register all implemented calls up to Object in this class to use send
      c.ancestors.each do | ancestor |
        break if ancestor == c.superclass 
        
        ancestor.public_instance_methods( false ).each do | method_name |
          c.define_blank_method( method_name, :public )
        end
        ancestor.protected_instance_methods( false ).each do | method_name |
          c.define_blank_method( method_name, :protected )
        end

        register_future_methods( ancestor, c )
      end
      c
    end

    def register_future_methods( klass, mi_klass )
      old_method_added = "_method_added_mi_#{unique_id}"
      klass.instance_eval %Q{
        alias :#{old_method_added} :method_added
        def method_added( method_name )
          ObjectSpace._id2ref( #{mi_klass.object_id} ).define_blank_method( 
              method_name )
          #{old_method_added}( method_name )
        end
      }
    end

    def unique_id
      @unique_id = ( @unique_id || 0 ) + 1
      "%.5d" % @unique_id
    end
  end
end
