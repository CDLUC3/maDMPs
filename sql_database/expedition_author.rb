class ExpeditionAuthor
  def initialize(hash)
    @source_id = params[:source_id]
    @expedition_id = params[:expedition_id]
    @author_id = params[:author_id]
  end

  # -------------------------------------------------
  def self.find(conn, hash)
    if valid?(hash)
      sql = "SELECT * \
             FROM expedition_authors \
             WHERE source_id = #{hash[:source_id]} \
             AND author_id = #{hash[:author_id]} \
             AND expedition_id = #{hash[:expedition_id]}"
    end
    object_from_hash(self.class, conn.query(sql).first)
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare("INSERT INTO expedition_authors \
                            (source_id, author_id, expedition_id) \
                           VALUES (?, ?, ?)")
      stmt.execute(hash[:source_id], hash[:author_id], hash[:expedition_id])
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
    !hash[:author_id].nil? && !hash[:source_id].nil? && !hash[:expedition_id].nil?
  end
end
