class Project
  @conn, @source = nil, nil
  @id, @title, @identifiers, @markers, @expeditions = nil, '', [], [], []

  def initialize(**params)
    unless params[:conn].nil? || params[:source].nil? || params[:json].nil?
      @conn = params[:conn]
      @source = params[:source]
      @title = params[:json]['projectTitle']
      @identifiers = params[:identifiers].map do |identifier|
        #new Identifier({source: source, identifier: identifier})
      end unless params[:identifiers].nil?
      @markers = params[:markers].map do |marker|
        #new Marker({source: source, marker: marker})
      end unless params[:markers].nil?
      @expeditions = params[:expeditions].map do |expedition|
        #new Expedition({source: source, expedition: expedition})
      end unless params[:expeditions].nil?
    end
  end

  def valid?
    if @id.present?
      prj = find_by_title_and_source(@title, @source) 
      @title.present? && prj.nil?
    else
      @title.present?
    end
  end

  def save!
    if @id.nil?
      create(self, @source)
    end
  end

  def title
    @title
  end
  def title=(val)
    @title = val
  end
  def identifiers
    @identifiers
  end
  def identifiers=(array)
    @identifiers = array || []
  end
  def markers
    @markers
  end
  def markers=(array)
    @markers = array || []
  end
  def expeditions
    @expeditions
  end
  def expeditions=(array)
    @expeditions = array || []
  end

  private
  def find_by_id(id)
    if self.conn.respond_to?(:query)
      db.query("SELECT * FROM projects WHERE id = ?", id).first
    else
      nil
    end
  end
  def find_by_identifiers(array)
    if self.conn.respond_to?(:query)
      db.query("SELECT * FROM project_identifiers WHERE identifier IN (?)",
               array.map{ |id| id.to_s.downcase }).first
    else
      nil
    end
  end
  def find_by_title_and_source(title, source)
    if self.conn.respond_to?(:query)
      db.query("SELECT * FROM projects WHERE LOWER(title) = ?", title.downcase).first
    else
      nil
    end
  end
  def create(project, source)
    if self.conn.respond_to?(:query)
      unless project.id.nil? and find_by_title_and_source(project.title, source).count <= 0
        db.execute("INSERT INTO projects (title, source_id, source_json) VALUES (?, ?, ?)",
                  project.title, source.id, source.json)
      end
    end
    find_by_title_and_source(project.title, source.id)
  end
  def update

  end
  def destroy

  end
end
