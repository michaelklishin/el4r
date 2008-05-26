(ENV['TESTS'] || '').split(/:/).each {|p|
  Dir[File.expand_path(p)].each {|rb|
    load rb
  }
}
