require 'cocoapods'
require 'claide/command/plugin_manager'

CLAide::Command::PluginManager.load_plugins('cocoapods')
Pod::Config.instance.silent = true

def generate_podfile(localizations = [], used_pods = [])
    Pod::Podfile.new do
        opts = {}
        opts[:localizations] = localizations unless localizations.empty?
        platform :ios, '9.0'
        plugin 'cocoapods-prune-localizations', opts
        
        target 'iOSTarget' do
            used_pods.each do |pod_dict|
                name = pod_dict[:name]
                opts = {}
                opts[:path] ||= pod_dict[:path]
                
                pod name, opts
            end
        end
    end
end

def lproj_in_bundle(bundle_path)
    lprojs = []
    Dir.foreach(bundle_path) do |filename|
        if filename.end_with? ".lproj"
            lprojs << File.basename(filename)
        elsif filename.end_with? ".bundle"
            lprojs += lproj_in_bundle(File.join(bundle_path, filename))
        end
    end
    lprojs
end

describe 'Podfile integration' do
    before(:each) do
        @test_dir = Dir.mktmpdir("prune-loc")
        @sandbox = Pod::Sandbox.new File.join(@test_dir, "/Pods");
        FileUtils.cp_r 'spec/fixtures/Dummy Targets', @test_dir
    end
    
    after(:each) do
        FileUtils.rm_r @sandbox.root
    end
    
    it 'calls original post_install hook' do
        Dir.chdir(@test_dir) do
            podfile = generate_podfile
            
            called = false
            podfile.post_install do |installer|
                called = true
            end
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            expect(called).to be_truthy
        end
    end
    
    it 'keeps only specified languages in Resources' do
        
        pods_to_use = [{:name => "FormatterKit"}]
        
        Dir.chdir(@test_dir) do
            langs = ["es.lproj", "en.lproj"]
            podfile = generate_podfile(langs, pods_to_use)
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            project = installer.pods_project
            group = project.pod_group("FormatterKit")
            
            resGroups = group.recursive_children_groups.select do |group|
                group.name == "Resources"
            end
            
            found_langs = Set.new
            
            resGroups.each do |resGroup|
                resGroup.files.each do |file|
                    if file.path.end_with? ".lproj"
                        found_langs.add File.basename(file.path)
                    end
                end
            end
            
            expect(found_langs).to eq langs.to_set
        end
    end
    
    it 'keeps only specified languages in Bundles' do
        
        pods_to_use = [{:name => "DateTools"}]
        
        Dir.chdir(@test_dir) do
            langs = ["es.lproj", "en.lproj"]
            podfile = generate_podfile(langs, pods_to_use)
            
            installer = Pod::Installer.new(@sandbox, podfile, nil)
            installer.installation_options.integrate_targets = false
            
            installer.install!
            
            project = installer.pods_project
            group = project.pod_group("DateTools")
            
            resGroups = group.recursive_children_groups.select do |group|
                group.name == "Resources"
            end
            
            found_bundles = []
            resGroups.each do |resGroup|
                resGroup.files.each do |file|
                    if file.path.end_with? ".bundle"
                        found_bundles << file.real_path
                    end
                end
            end
            
            found_langs = found_bundles.map {|path| lproj_in_bundle(path)}.flatten!.to_set
            expect(found_langs).to eq langs.to_set
        end
    end
    
end