class Marker
  def initialize(hash)
    @source_id = params[:source_id]
    @project_id = params[:project_id]
    @value = params['value']
    @uri = params['uri']
    @defined_by = params['defined_by']
    @source_json = params[:source_json]
  end

  # -------------------------------------------------
  def self.find_all(conn, hash)
    ret = []
    if !hash[:project_id].nil? && !hash[:source_id].nil?
      recs = conn.query("SELECT * \
                         FROM markers \
                         WHERE source_id = #{hash[:source_id]} \
                         AND project_id = #{hash[:project_id]}")
      recs.each do |rec|
        ret << object_from_hash(self.class, rec)
      end
    end
    ret
  end

  # -------------------------------------------------
  def self.find(conn, hash)
    if hash[:project_id].nil? && !hash['value'].nil?
      sql = "SELECT * \
             FROM markers \
             WHERE source_id = #{hash[:source_id]} \
             AND value = '#{hash['value']}'"
    else
      sql = "SELECT * \
             FROM markers \
             WHERE source_id = #{hash[:source_id]} \
             AND project_id = #{hash[:project_id]} \
             AND value = '#{hash['value']}'"
    end
    object_from_hash(self.class, conn.query(sql).first)
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare(
        "INSERT INTO markers \
          (source_id, source_json, project_id, value, uri, defined_by, definition) \
        VALUES (?, ?, ?, ?, ?, ?, ?)")
      stmt.execute(hash[:source_id], hash[:source_json], hash[:project_id],
                   hash['value'], hash['uri'], hash['defined_by'], hash['definition'])
      conn.last_id
    else
      nil
    end
  end

  # -------------------------------------------------
  def id
    @id
  end
  def project_id
    @project_id
  end
  def source_id
    @source_id
  end
  def value
    @value
  end
  def uri
    @uri
  end
  def defined_by
    @defined_by
  end
  def definition
    @definition
  end

private
  def self.valid?(hash)
    !hash['value'].nil? && !hash[:source_id].nil? && !hash[:project_id].nil?
  end
end
