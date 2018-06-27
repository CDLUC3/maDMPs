class Author
  def initialize(hash)
    @source_id = params[:source_id]
    @name = params['username']
  end

  # -------------------------------------------------
  def self.find(conn, hash)
    if valid?(hash)
      sql = "SELECT * \
             FROM authors \
             WHERE source_id = #{hash[:source_id]} \
             AND name = '#{hash['username']}'"
      object_from_hash(self.class, conn.query(sql).first)
    else
      nil
    end
  end

  # -------------------------------------------------
  def self.create!(conn, hash)
    if conn.respond_to?(:query) && valid?(hash)
      stmt = conn.prepare(
        "INSERT INTO authors (source_id, name) VALUES (?, ?)")
      stmt.execute(hash[:source_id], hash['username'])
      author_id = conn.last_id

      # Tie authors to their expedition
      exp_auth_hash = { expedition_id: hash[:expedition_id], author_id: author_id }
      if ExpeditionAuthor.find(conn, exp_auth_hash).nil?
        ExpeditionAuthor.create!(conn, exp_auth_hash)
      end
      # Tie author to project if they are Admin/PI
      if hash[:pi].to_s == 'true'
        prj_auth_hash = { project_id: hash[:project_id], author_id: author_id }
        if ProjectAuthor.find(conn, prj_auth_hash).nil?
          ProjectAuthor.create!(conn, prj_auth_hash)
        end
      end
      author_id
    else
      nil
    end
  end

  # -------------------------------------------------
  def id
    @id
  end
  def name
    @name
  end

private
  def self.valid?(hash)
    !hash['username'].nil? && !hash[:source_id].nil?
  end
end
