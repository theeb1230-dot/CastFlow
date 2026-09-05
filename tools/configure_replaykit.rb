#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

project_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |target| target.name == 'Runner' }
abort('Runner target not found') unless runner

extension_name = 'BroadcastUploadExtension'
extension_target = project.targets.find { |target| target.name == extension_name }

group = project.main_group.find_subpath(extension_name, true)
group.set_source_tree('<group>')
group.path = extension_name

sample_path = 'SampleHandler.swift'
sample_ref = group.files.find { |file| file.path == sample_path } || group.new_file(sample_path)

unless extension_target
  extension_target = project.new_target(
    :app_extension,
    extension_name,
    :ios,
    '13.0'
  )
end

unless extension_target.source_build_phase.files_references.include?(sample_ref)
  extension_target.add_file_references([sample_ref])
end

extension_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] =
    'com.castflow.castflow.BroadcastUploadExtension'
  config.build_settings['PRODUCT_NAME'] = extension_name
  config.build_settings['PRODUCT_MODULE_NAME'] = extension_name
  config.build_settings['EXECUTABLE_NAME'] = '$(PRODUCT_NAME)'
  config.build_settings['WRAPPER_EXTENSION'] = 'appex'
  config.build_settings['INFOPLIST_FILE'] =
    'BroadcastUploadExtension/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] =
    'BroadcastUploadExtension/BroadcastUploadExtension.entitlements'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
  config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  config.build_settings['SKIP_INSTALL'] = 'YES'
end

runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

unless runner.dependencies.any? { |dependency| dependency.target == extension_target }
  runner.add_dependency(extension_target)
end

embed_phase =
  runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' } ||
  runner.new_copy_files_build_phase('Embed App Extensions')
embed_phase.dst_subfolder_spec = '13'

product_ref = extension_target.product_reference
unless embed_phase.files_references.include?(product_ref)
  embed_phase.add_file_reference(product_ref, true)
end

thin_binary_index = runner.build_phases.index do |phase|
  phase.respond_to?(:name) && phase.name == 'Thin Binary'
end
if thin_binary_index
  runner.build_phases.delete(embed_phase)
  runner.build_phases.insert(thin_binary_index, embed_phase)
end

project.save
