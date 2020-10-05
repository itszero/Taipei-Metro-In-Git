#!/usr/bin/env ruby
require 'json'

data = JSON.parse(File.read("data.json"))
data = data.filter { |route| route["Direction"] == 0 }

def get_station_name(station)
  station["StationName"]["Zh_tw"]
end

stations = []
edges = {}
data.each do |route|
  route["Stations"].each_cons(2) do |s1, s2|
    # We can't use the StationID because one station can have different ID on each line
    edges[get_station_name(s1)] = {} if edges[get_station_name(s1)].nil?
    edges[get_station_name(s1)][get_station_name(s2)] = true
    stations << get_station_name(s1)
    stations << get_station_name(s2)
  end
end

stations.uniq!

def create_commit(stationName, parents, skipTag=false)
  treeId = `git write-tree`.strip
  parentArg = parents.map { |parentId| "-p #{parentId}" }.join(' ')
  commitId = `git commit-tree #{parentArg} -m '#{stationName}' #{treeId}`.strip
  system("git tag #{stationName} #{commitId}") if not skipTag

  return commitId
end

def create_station_commit(stationName, edges, visited, from)
  if visited[stationName] == :PENDING
    # oops, we found a cyclic
    puts "Cyclic found: #{from} -> #{stationName}. The link will be broken."
    return nil
  elsif not visited[stationName].nil?
    return visited[stationName]
  end

  visited[stationName] = :PENDING
  deps = (edges[stationName] || {}).keys.map { |fromStation| [fromStation, create_station_commit(fromStation, edges, visited, stationName)] }.reject { |name, commitId| commitId.nil? }
  commitId = nil
  if deps.size == 0
    # create the commit
    commitId = create_commit(stationName, [])
    puts "Create commit for #{stationName} (ID: #{commitId})"
  elsif deps.size == 1
    commitId = create_commit(stationName, deps.map(&:last))
    puts "Create commit for #{stationName} (ID: #{commitId}) - Parent: #{deps}"
  else
    commitId = create_commit(stationName, deps.map(&:last))
    puts "Create merge commit for #{stationName} (ID: #{commitId}) - Parents: #{deps}"
  end

  if commitId.nil?
    raise "Unable to create a commit for #{stationName}"
  else
    visited[stationName] = commitId
  end
  return commitId
end

visited = {}
system("rm -rf out; mkdir out; cd out; git init")
Dir.chdir "out"
stations.each do |station|
  puts "Traversing map from: #{station}"
  lastCommitId = create_station_commit(station, edges, visited, nil)
end

heads = []
data.each do |route|
  firstStation = get_station_name(route["Stations"].first)
  branchName = "#{route["LineID"]} #{route["RouteName"]["Zh_tw"]}".gsub(' ', '-')
  puts "Creating branch: #{branchName} -> #{firstStation} (#{visited[firstStation]})"
  system("git branch \"#{branchName}\" #{visited[firstStation]}")
  heads << visited[firstStation]
end
heads.uniq!

system("rsync -av --progress .. . --exclude out --exclude .git --exclude data.json")
system("git add .")
startHereCommitId = create_commit("Start Here", heads, true)
system("git checkout -b master #{startHereCommitId}")