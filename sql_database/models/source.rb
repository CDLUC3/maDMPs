class Source < ActiveRecord::Base
  has_many :api_scans
  has_many :projects
  has_many :orgs
  has_many :contributors
  has_many :stages
  
  def downloader
    if self.directory.present?
      path = File.expand_path("..", Dir.pwd)
      path += "/#{self.directory}"
      Dir["#{path}/*.rb"].each {|file| require file }

      # Instantiate the source downloaded
      begin
        clazz_name = self.name.gsub(/\s/, '').split(/_|\-/).to_a.reduce(''){ |out, part| out + part.capitalize }
        clazz = Object.const_get(clazz_name)
        obj = clazz.new
        (obj.respond_to?(:download) ? obj : nil)
      rescue NameError => ne
        puts "Unable to initialize the downloader for #{self.name}: #{ne.message}"
      end
    else
      puts "no downloader directory specified for #{self.name}"
    end
  end
end
