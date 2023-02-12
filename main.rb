#!/usr/bin/env ruby
require 'json'

def get_station_name(station)
  "#{station["StationName"]["Zh_tw"]}-#{station["StationName"]["En"].gsub(/[ ']/, '_')}"
end

lines = []
stations = []
edges = {}
lines_meta = []

def process_file(prefix, data, data_lines, stations, edges, lines, lines_meta)
  data.each do |route|
    lines_meta << [prefix, route["LineID"], get_station_name(route["Stations"].first)]
    route["Stations"].each_cons(2) do |s1, s2|
      # We can't use the StationID because one station can have different ID on each line
      edges[get_station_name(s1)] = {} if edges[get_station_name(s1)].nil?
      edges[get_station_name(s1)][get_station_name(s2)] = true
      stations << get_station_name(s1)
      stations << get_station_name(s2)
    end
  end

  [stations, edges, lines.concat(data_lines), lines_meta]
end

if File.exists? 'Line-TRTC.json'
  stations, edges, lines = process_file('TRTC', JSON.parse(File.read("StationOfLine-TRTC.json")), JSON.parse(File.read("Line-TRTC.json")), stations, edges, lines, lines_meta)
end
if File.exists? 'Line-TYMC.json'
  stations, edges, lines = process_file('TYMC', JSON.parse(File.read("StationOfLine-TYMC.json")), JSON.parse(File.read("Line-TYMC.json")), stations, edges, lines, lines_meta)
end
if File.exists? 'Line-NTDLRT.json'
  stations, edges, lines = process_file('NTDLRT', JSON.parse(File.read("StationOfLine-NTDLRT.json")), JSON.parse(File.read("Line-NTDLRT.json")), stations, edges, lines, lines_meta)
end
if File.exists? 'Line-TRTCMG.json'
  stations, edges, lines = process_file('TRTCMG', JSON.parse(File.read("StationOfLine-TRTCMG.json")), JSON.parse(File.read("Line-TRTCMG.json")), stations, edges, lines, lines_meta)
end

stations.uniq!

def create_commit(stationName, parents, skipTag=false)
  treeId = `git write-tree`.strip
  parentArg = parents.map { |parentId| "-p #{parentId}" }.join(' ')
  commitId = `git commit-tree #{parentArg} -m '#{stationName}' #{treeId}`.strip
  system("git tag '#{stationName}' #{commitId}") if not skipTag

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
lines_meta.each do |prefix, lineID, firstStation|
  line = lines.find { |line| line["LineID"] == lineID }
  branchName = "#{prefix}-#{line["LineID"]} #{line["LineName"]["Zh_tw"]} #{line["LineName"]["En"]}".gsub(' ', '-')
  puts "Creating branch: #{branchName} -> #{firstStation} (#{visited[firstStation]})"
  system("git branch \"#{branchName}\" #{visited[firstStation]}")
  heads << visited[firstStation]
end
heads.uniq!

system("rsync -av --progress .. . --exclude out --exclude .git --exclude *.json")
system("git add .")
startHereCommitId = create_commit("Start Here", heads, true)
system("git checkout -b master #{startHereCommitId}")