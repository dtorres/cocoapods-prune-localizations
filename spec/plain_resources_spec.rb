require 'cocoapods'
require 'cocoapods-prune-localizations'
require 'claide/command/plugin_manager'

CLAide::Command::PluginManager.load_plugins('cocoapods')
Pod::Config.instance.silent = true

def generate_podfile
    Pod::Podfile.new do
        platform :ios
        plugin 'cocoapods-prune-localizations', {:localizations => ["en", "es"]}
        
        target 'iOSTarget' do
            pod 'FormatterKit'
        end
    end
end

describe 'Podfile integration' do
    before(:all) do
        @sandbox = Pod::Sandbox.new Dir.mktmpdir("prune-loc")
    end
    
    after(:all) do
        FileUtils.rm_r @sandbox.root
    end
    
    it 'keeps specified languages' do
        
        langs = ["es.lproj", "en.lproj"]
        
        FileUtils.cp_r 'spec/fixtures/Dummy Targets', @sandbox.root
        installer = Pod::Installer.new(@sandbox, generate_podfile, nil)
        installer.installation_options.integrate_targets = false
        
        installer.install!
        
        #Verify only en, es resources are available
        project = Xcodeproj::Project.open(installer.pods_project.path)
        
        pod_groups = []
        pod_items = project["Pods"]
        dev_pod_items = project["Development Pods"]
        pod_groups += pod_items.children.objects if pod_items
        pod_groups += dev_pod_items.children.objects if dev_pod_items
        
        pod_groups.each do |group|
            resGroups = group.recursive_children_groups.select do |group|
                group.name == "Resources"
            end
            next unless resGroups.length > 0
            
            resGroups.each do |resGroup|
                subTrimmedBundlesToAdd = Hash.new
                resGroup.files.each do |file|
                    if file.path.end_with? ".lproj"
                        expect(langs).to include(File.basename(file.path))
                    end
                end
            end
        end
    end
end