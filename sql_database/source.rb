class Source
  @conn, @id, @name, @downloader = nil, nil, nil, nil

  def initialize(**params)
    @conn = params[:conn]
    @id = params[:id]
    @name = params[:name]
    @downloader = init_downloader(params[:downloader_dir])
  end

  def self.all(conn)
    if conn.respond_to?(:query)
      res = conn.query("SELECT * FROM sources ORDER BY name")
      res.to_a.map do |record|
        Source.new({
          conn: conn,
          id: record['id'],
          name: record['name'],
          downloader_dir: record['directory']
        })
      end
    else
      []
    end
  end

  def id
    @id
  end
  def name
    @name
  end
  def name=(val)
    @name = val
  end
  def downloader
    @downloader
  end
  def downloader=(val)
    @downloader = val
  end

  private
  def init_downloader(dir)
    path = File.expand_path("..", Dir.pwd)
    path += "/#{dir}"
    Dir["#{path}/*.rb"].each {|file| require file }

    # Instantiate the source downloaded
    begin
      clazz = Object.const_get("#{@name.gsub(/\s/, '').capitalize}")
      obj = clazz.new
      (obj.respond_to?(:download) ? obj : nil)
    rescue NameError => ne
      puts "No downloader defined for #{@name}"
    end
  end
end
