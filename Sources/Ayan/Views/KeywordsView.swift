import SwiftUI
import SwiftData

struct KeywordsView: View {
    @AppStorage("customCodeRoots") private var codeRoots = "apps, Sites, Code, Developer, projects, work, github, repositories, src, lab"
    @AppStorage("customServiceNames") private var serviceNames = "cPanel, Vercel, Netlify, Heroku, Supabase, Firebase, Linear, Slack, Discord, Appray"
    @AppStorage("customBlacklist") private var blacklistedWords = "google, github, localhost, 127, apple, microsoft, amazon, facebook, twitter, linkedin, Home, Index, Login, Dashboard, Untitled, Google Search, Privacy Policy, Terms of Service, node, python, bash, zsh, docker, root, admin, main, master, develop, debug, release, documents, desktop, downloads, library, applications, users, pictures, movies, public, shared, bin, etc, var, tmp"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection Keywords")
                .font(.title2).bold()
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Code Directory Roots")
                            .font(.headline)
                        Text("Ayan detects projects when it sees these folders in your file paths (e.g., in iTerm or VSCode).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $codeRoots)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 60)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SaaS & Service Names")
                            .font(.headline)
                        Text("Common web services Ayan should recognize as their own projects.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $serviceNames)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 60)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ignored Noise (Blacklist)")
                            .font(.headline)
                        Text("Generic words that should NEVER be turned into an auto-detected project.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $blacklistedWords)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 100)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Text("Keywords must be separated by commas.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .padding(.top)
    }
}
