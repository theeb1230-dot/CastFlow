#!/usr/bin/env ruby
# frozen_string_literal: true

require 'xcodeproj'

project_path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

runner = project.targets.find { |target| target.name == 'Runner' }
abort('Runner target not found') unless runner

extension_name = 'BroadcastUploadExtension'
extension_target = project.targets.find { |target| target.name == extension_name }

extension_group = project.main_group.find_subpath(extension_name, true)
extension_group.set_source_tree('<group>')
extension_group.path = extension_name

extension_source_paths = %w[
  SampleHandler.swift
  VideoToolboxH264Encoder.swift
]
extension_source_refs = extension_source_paths.map do |source_path|
  extension_group.files.find { |file| file.path == source_path } ||
    extension_group.new_file(source_path)
end

unless extension_target
  extension_target = project.new_target(
    :app_extension,
    extension_name,
    :ios,
    '13.0'
  )
end

extension_source_refs.each do |source_ref|
  unless extension_target.source_build_phase.files_references.include?(source_ref)
    extension_target.add_file_references([source_ref])
  end
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

runner_group = project.main_group.find_subpath('Runner', true)
runner_source_path = 'ReplayKitSpoolBridge.swift'
runner_source_ref =
  runner_group.files.find { |file| file.path == runner_source_path } ||
  runner_group.new_file(runner_source_path)
unless runner.source_build_phase.files_references.include?(runner_source_ref)
  runner.add_file_references([runner_source_ref])
end

app_delegate_path = File.expand_path('../ios/Runner/AppDelegate.swift', __dir__)
registration_line = 'ReplayKitSpoolBridge.register(with: self)'
unless File.exist?(app_delegate_path)
  abort('Generated AppDelegate.swift not found')
end

app_delegate = File.read(app_delegate_path)
unless app_delegate.include?(registration_line)
  marker = 'GeneratedPluginRegistrant.register(with: self)'
  abort('GeneratedPluginRegistrant marker not found in AppDelegate.swift') unless app_delegate.include?(marker)

  app_delegate = app_delegate.sub(
    marker,
    "#{marker}\n    #{registration_line}"
  )
  File.write(app_delegate_path, app_delegate)
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
