#!/usr/bin/env ruby
require 'rubygems'
require 'gollum/app'

gollum_path = File.expand_path('/wiki')
wiki_options = {:universal_toc => false, index_page: "BOX4security", page_file_dir: "BOX4security"}
Precious::App.set(:gollum_path, gollum_path)
Precious::App.set(:default_markup, :markdown)
Precious::App.set(:wiki_options, wiki_options)

require 'rack'

# set author
class Precious::App
    def headers
        env.
          select { |k,v| k.start_with? 'HTTP_'}.
          transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') }.
          sort.to_h.
          tap do |headers|
            headers.define_singleton_method :[] do |k|
              super(k.split(/[-_]/).map(&:capitalize).join('-'))
            end
          end
      end
    before do
        puts env
        session['gollum.author'] = {
            :name => env['X-Auth-Username'],
            :email => "box@4sconsult.de",
        }
    end
end

class MapGollum
    def initialize base_path
        @mg = Rack::Builder.new do
            map '/' do
                run Proc.new { [302, { 'Location' => "/#{base_path}" }, []] }
            end
            map "/#{base_path}" do
                run Precious::App
            end
        end
    end

    def call(env)
        @mg.call(env)
    end
end

# Rack::Handler does not work with Ctrl + C. Use Rack::Server instead.
Rack::Server.new(:app => MapGollum.new("wiki"), :Port => 80, :Host => '0.0.0.0').start

