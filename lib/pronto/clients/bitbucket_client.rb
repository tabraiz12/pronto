class BitbucketClient
  include HTTParty
  base_uri 'https://api.bitbucket.org/2.0/repositories'

  def initialize(username, password)
    self.class.basic_auth(username, password)
  end

  def commit_comments(slug, sha)
    response = get_all_comments("/#{slug}/changesets/#{sha}/comments?pagelen=100")
    parse_comments(openstruct(response))
  end

  def create_commit_comment(slug, sha, body, path, position)
    post("/#{slug}/changesets/#{sha}/comments", body, path, position)
  end

  def pull_comments(slug, pull_id)
    response = get_all_comments("/#{slug}/pullrequests/#{pull_id}/comments?pagelen=100")
    parse_comments(openstruct(response))
  end

  def pull_requests(slug)
    response = get("/#{slug}/pullrequests?state=OPEN")
    openstruct(response['values'])
  end

  def create_pull_comment(slug, pull_id, body, path, position)
    post("/#{slug}/pullrequests/#{pull_id}/comments", body, path, position)
  end

  def approve_pull_request(slug, pull_id)
    self.class.post("/#{slug}/pullrequests/#{pull_id}/approve")
  end

  def unapprove_pull_request(slug, pull_id)
    self.class.delete("/#{slug}/pullrequests/#{pull_id}/approve")
  end

  private

  def get_all_comments(url)
    all_comments = []
    comments = get(url)
    all_comments = all_comments + comments['values']
    if comments['next']
      get_all_comments(comments['next'])
    else
      all_comments
    end
  end

  def openstruct(response)
    response.map { |r| OpenStruct.new(r) }
  end

  def parse_comments(values)
    values.each do |value|
      value.content = value.content['raw']
      value.line_to = value.inline['to']
      value.filename = value.inline['path']
    end
    values
  end
  
  def post(url, body, path, position)
    options = {
      body: {
        content: {
          raw: body
        },
        inline: {
          to: position,
          path: path
        }
      }.to_json,
      headers: {
        'Content-Type': 'application/json'
      }
    }
    self.class.post(url, options)
  end

  def get(url)
    self.class.get(url).parsed_response
  end
end
