module Words
  STOP_WORDS = [
    'project', 'plan', 'dr.', 'dr', 'phd', 'p.h.d.',
    'a','cannot','into','our','thus','about','co','is','ours','to','above',
    'could','it','ourselves','together','across','down','its','out','too',
    'after','during','itself','over','toward','afterwards','each','last','own',
    'towards','again','eg','latter','per','under','against','either','latterly',
    'perhaps','until','all','else','least','rather','up','almost','elsewhere',
    'less','same','upon','alone','enough','ltd','seem','us','along','etc',
    'many','seemed','very','already','even','may','seeming','via','also','ever',
    'me','seems','was','although','every','meanwhile','several','we','always',
    'everyone','might','she','well','among','everything','more','should','were',
    'amongst','everywhere','moreover','since','what','an','except','most','so',
    'whatever','and','few','mostly','some','when','another','first','much',
    'somehow','whence','any','for','must','someone','whenever','anyhow',
    'former','my','something','where','anyone','formerly','myself','sometime',
    'whereafter','anything','from','namely','sometimes','whereas','anywhere',
    'further','neither','somewhere','whereby','are','had','never','still',
    'wherein','around','has','nevertheless','such','whereupon','as','have',
    'next','than','wherever','at','he','no','that','whether','be','hence',
    'nobody','the','whither','became','her','none','their','which','because',
    'here','noone','them','while','become','hereafter','nor','themselves','who',
    'becomes','hereby','not','then','whoever','becoming','herein','nothing',
    'thence','whole','been','hereupon','now','there','whom','before','hers',
    'nowhere','thereafter','whose','beforehand','herself','of','thereby','why',
    'behind','him','off','therefore','will','being','himself','often','therein',
    'with','below','his','on','thereupon','within','beside','how','once',
    'these','without','besides','however','one','they','would','between','i',
    'only','this','yet','beyond','ie','onto','those','you','both','if','or',
    'though','your','but','in','other','through','yours','by','inc','others',
    'throughout','yourself','can','indeed','otherwise','thru','yourselves'
    ]
  TOKEN_REGEXP = /^[a-z]+$|^\w+\-\w+|^[a-z]+[0-9]+[a-z]+$|^[0-9]+[a-z]+|^[a-z]+[0-9]+$/

  def self.is?(token)
    STOP_WORDS.member?(token)
  end

  def self.valid?(token)
    (((token =~ TOKEN_REGEXP) == 0) &&
     !(token =~ /^[\d\.]+$/) &&           # no numbers
     !(token =~ /^http/) &&               # No URLs
     !(token =~ /^[a-fA-F0-9]{4,}$/) &&   # No UUIDs (dashes already removed)
     !(STOP_WORDS.member?(token)))
  end

  def self.cleanse(text)
    text.downcase.gsub('-', ' ').split(' ').select{ |w| valid?(w) }
  end

  def self.text_to_acronym(text)
    capitalized = text.gsub('-', ' ').scan(/[\p{Lu}\p{Lt}]/)
    capitalized.map{ |w| w[0] }.join('').to_s
  end

  def self.match_percent(textA, textB)
    wordsA = cleanse(textA)
    wordsB = cleanse(textB)
    if wordsA.present? && wordsB.present?
      if wordsA.eql?(wordsB)
        1.0
      elsif text_to_acronym(textA).length > 2 && text_to_acronym(textB).length > 2 &&
              text_to_acronym(textA) == text_to_acronym(textB)
        1.0
      else
        if wordsA.select{ |w| wordsB.include?(w) }.length > 0
          (((wordsA.select{ |w| wordsB.include?(w) }.length / wordsA.length) + (wordsB.select{ |w| wordsA.include?(w) }.length / wordsB.length)) / 2).to_f
        else
          0
        end
      end
    else
      0
    end
  end
end
