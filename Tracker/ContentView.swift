//
//  ContentView.swift
//  Tracker
//
//  Created by Dylan Elliott on 21/12/2023.
//

import SwiftUI
import Combine
import DylKit
import WebViewKit

enum Status: String, Codable {
    case vip
    case member
    case trusted
}
struct Torrent: Codable, Identifiable {
    let id: String
    let name: String
    let leechers: String
    let seeders: String
    let info_hash: String
    let status: Status
    let size: String
    let imdb: String
    
    var ratio: CGFloat {
        guard let seeders = Float(seeders), let leechers = Float(leechers) else { return 0 }
        return CGFloat(seeders / leechers)
    }
    
    var isVIP: Bool { [.vip, .trusted].contains(status) }
    
    var fileSize: String {
        guard let size = Float(size) else { return "???" }
        
        let kilobytes = size / 1024.0
        
        if kilobytes < 1000 {
            return "\(Int(kilobytes)) kb"
        }
        
        let megabytes = kilobytes / 1024.0
        
        if megabytes < 1000 {
            return "\(Int(megabytes)) Mb"
        }
        
        let gigabytes = megabytes / 1024.0
        
        return String(format: "%.2f Gb", gigabytes)
    }
    
    var imdbURL: URL? {
        guard !imdb.isEmpty else { return nil }
        return .init(string: "https://www.imdb.com/title/\(imdb)/")
    }
}

final class ContentViewModel: ObservableObject {
    
    @Published var torrents: [Torrent] = []
    @Published var text: String = ""
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    init() {
        self.$text
            .throttle(for: 1, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in
                self?.search($0)
            }.store(in: &cancellables)
    }
    
    private func search(_ query: String) {
        let sanitisedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: "https://apibay.org/q.php?q=\(sanitisedQuery)")!
        URLSession.shared.dataTask(with: .init(url: url)) { data, response, error in
            guard let data = data else { return }
            
            onMain {
                do {
                    
                    self.torrents = try JSONDecoder().decode([Torrent].self, from: data)
                        .filter { $0.id != "0" }
//                        .sorted(by: { $0.ratio > $1.ratio })
                } catch {
                    print(error.localizedDescription)
                    print(data.string ?? "NO DATA")
                }
            }
        }
        .resume()
    }
    
    func torrentTapped(_ torrent: Torrent) {
        SharedApplication.openURL(.init(string: "magnet:?xt=urn:btih:\(torrent.info_hash)")!)
    }
}

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel = .init()
    @State var webViewURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            TextField("Query", text: $viewModel.text)
                .textFieldStyle(.plain)
                .placeholder(when: viewModel.text.isEmpty, alignment: .center) {
                    Text("Query").foregroundColor(.gray)
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(5)
                .padding(.top, 5)
                .font(.largeTitle)
                .accentColor(.blue)
            
            if !viewModel.torrents.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(enumerated: viewModel.torrents) { index, torrent in
                            HStack {
                                if let imdbURL = torrent.imdbURL {
                                    Button {
                                        webViewURL = imdbURL
                                    } label: {
                                        Image(systemName: "film")
                                    }
                                    .buttonStyle(.plain)
                                }
                                Button {
                                    viewModel.torrentTapped(torrent)
                                } label: {
                                    Text(torrent.name)
                                }
                                .buttonStyle(.plain)
                                
                                if torrent.isVIP {
                                    Image(systemName: "checkmark")
                                }
                                
                                Text("(\(torrent.fileSize))")
                                
                                Spacer()
                                
                                HStack {
                                    HStack(spacing: 2) {
                                        Image(systemName: "arrow.up")
                                        Text(torrent.seeders)
                                    }
                                    
                                    HStack(spacing: 2) {
                                        Image(systemName: "arrow.down")
                                        Text(torrent.leechers)
                                    }
                                }
                            }
                            .padding(5)
                            .foregroundStyle(Color.rainbowColors[looping: index])
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(.black)
        .font(.title2)
        .bold()
        .sheet(item: $webViewURL) { url in
            WebView(url: url)
                .frame(minHeight: 500)
        }
    }
}

#Preview {
    ContentView()
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
