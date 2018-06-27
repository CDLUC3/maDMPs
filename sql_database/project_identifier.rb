class ProjectIdentifier
  def initialize(hash)
    @source_id = params[:source_id]
    @project_id = params[:project_id]
    @identifier = params[:identifier]
  end

  # -------------------------------------------------
  def self.find_all(conn, hash)
    ret = []
    if !hash[:project_id].nil? && !hash[:source_id].nil?
      recs = conn.query("SELECT * \
                         FROM project_identifiers \
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
    if hash[:project_id].nil?
      sql = "SELECT * \
             FROM project_identifiers \
             WHERE source_id = #{hash[:source_id]} \
             AND identifier = '#{hash[:identifier]}'"
    else
      sql = "SELECT * \
             FROM project_identifiers \
             WHERE source_id = #{hash[:source_id]} \
             AND project_id = #{hash[:project_id]} \
             AND identifier = '#{hash[:identifier]}'"
    end
    object_from_hash(self.class, conn.query(sql).first)
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare("INSERT INTO project_identifiers \
                            (source_id, project_id, identifier) \
                           VALUES (?, ?, ?)")
      stmt.execute(hash[:source_id], hash[:project_id], hash[:identifier])
      find(conn, hash)
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

private
  def self.valid?(hash)
    !hash[:project_id].nil? && !hash[:source_id].nil? && !hash[:identifier].nil?
  end
end
