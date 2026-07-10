#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'uri'

trivy_mode = ARGV.include?("--trivy")

TARGETS = [
  { df_path: "stable/Dockerfile", image: "debian", tag: "stable-slim" },
  { df_path: "unstable/Dockerfile", image: "debian", tag: "unstable-slim" }
]

def get_latest_digest(image, tag)
  # 1. Docker Hubから匿名トークンを取得
  token_url = URI("https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/#{image}:pull")
  token_response = Net::HTTP.get(token_url)
  token_data = JSON.parse(token_response)
  token = token_data['token']
  
  if token.nil? || token == 'null'
    raise "Failed to get token for #{image}"
  end
  
  # 2. マニフェスト情報を要求し、レスポンスヘッダからダイジェストを取得
  manifest_url = URI("https://registry-1.docker.io/v2/library/#{image}/manifests/#{tag}")
  
  req = Net::HTTP::Head.new(manifest_url)
  req['Authorization'] = "Bearer #{token}"
  req['Accept'] = "application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"
  
  res = Net::HTTP.start(manifest_url.hostname, manifest_url.port, use_ssl: true) do |http|
    http.request(req)
  end
  
  digest = res['docker-content-digest']
  if digest.nil? || digest.empty?
    raise "Could not retrieve digest for #{image}:#{tag}"
  end
  
  digest.strip
end

def log_to_changelog(message)
  changelog_path = "CHANGELOG.md"
  
  unless File.exist?(changelog_path)
    File.write(changelog_path, "# CHANGELOG\n\nAll notable changes to this project will be documented in this file.\n\n<!-- CHANGELOG_PLACEHOLDER -->\n")
  end
  
  content = File.read(changelog_path)
  today = Time.now.strftime("%Y-%m-%d")
  log_entry = "- [#{today}] #{message}"
  
  if content.include?(log_entry)
    puts "Changelog entry already exists: #{log_entry}"
    return
  end
  
  if content.include?("<!-- CHANGELOG_PLACEHOLDER -->")
    new_content = content.gsub("<!-- CHANGELOG_PLACEHOLDER -->", "<!-- CHANGELOG_PLACEHOLDER -->\n#{log_entry}")
    File.write(changelog_path, new_content)
    puts "Added to CHANGELOG: #{log_entry}"
  else
    File.write(changelog_path, "\n#{log_entry}\n", mode: 'a')
    puts "Added to CHANGELOG (append): #{log_entry}"
  end
end

TARGETS.each do |target|
  df_path = target[:df_path]
  image = target[:image]
  tag = target[:tag]
  
  puts "Checking #{df_path} (#{image}:#{tag})..."
  
  unless File.exist?(df_path)
    puts "Warning: File #{df_path} does not exist. Skipping."
    next
  end
  
  begin
    latest_digest = get_latest_digest(image, tag)
    puts "Latest digest: #{latest_digest}"
    
    # ファイル読み込みと置換処理
    content = File.read(df_path)
    
    # FROM <image>:<tag> または FROM <image>:<tag>@sha256:<hash> にマッチする正規表現
    pattern = /FROM\s+#{Regexp.escape(image)}:#{Regexp.escape(tag)}(@sha256:[a-f0-9]{64})?/
    
    if content =~ pattern
      new_content = content.gsub(pattern, "FROM #{image}:#{tag}@#{latest_digest}")
      
      if content != new_content
        File.write(df_path, new_content)
        puts "Updated #{df_path} successfully."
        log_to_changelog("Updated #{df_path} (#{image}:#{tag}) to @#{latest_digest}")
      elsif trivy_mode
        # FROMのダイジェストは変わっていないが、Trivy脆弱性検知モードの場合
        # コメントを挿入・更新してキャッシュを破棄し、差分を作る
        security_comment = "# SECURITY_UPDATE: #{Time.now.strftime("%Y-%m-%d")}"
        
        if new_content =~ /# SECURITY_UPDATE: \d{4}-\d{2}-\d{2}/
          new_content_with_comment = new_content.gsub(/# SECURITY_UPDATE: \d{4}-\d{2}-\d{2}/, security_comment)
        else
          # FROM行の直後に挿入
          new_content_with_comment = new_content.gsub(/(FROM\s+.*)/, "\\1\n#{security_comment}")
        end
        
        if content != new_content_with_comment
          File.write(df_path, new_content_with_comment)
          puts "Force updated #{df_path} with security comment to bust cache."
          log_to_changelog("Rebuilt #{df_path} for security updates (no base image changes)")
        else
          puts "#{df_path} is already up-to-date with today's security comment."
        end
      else
        puts "#{df_path} is already up-to-date. No changes made."
      end
    else
      puts "Warning: No matching FROM instruction found in #{df_path}."
    end
  rescue => e
    warn "Error updating #{df_path}: #{e.message}"
    exit 1
  end
  puts "----------------------------------------"
end
