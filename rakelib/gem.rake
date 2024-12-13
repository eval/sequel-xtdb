namespace :gem do
  task "write_version", [:version] do |_task, args|
    if args[:version]
      version = args[:version].split("=").last
      version_file = File.expand_path("../../lib/sequel/xtdb/version.rb", __FILE__)

      system(<<~CMD, exception: true)
        ruby -pi -e 'gsub(/VERSION = ".*"/, %{VERSION = "#{version}"})' #{version_file}
      CMD
      Bundler.ui.confirm "Version #{version} written to #{version_file}."
    else
      Bundler.ui.warn "No version provided, keeping version.rb as is."
    end
  end

  desc "Build [version]"
  task "build", [:version] => ["write_version", "build"] do
  end

  desc "Build and push [version] to rubygems"
  task "release", [:version] => ["gem:build", "release:rubygem_push"] do
  end
end
