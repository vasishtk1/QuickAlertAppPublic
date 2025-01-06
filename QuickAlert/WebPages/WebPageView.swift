//
//  WebPageView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 7/1/24.
//

import Foundation
import SwiftUI
import WebKit

/**
 creates the view for web page viewer in a desktop browser mode
 saves the HTML file for the web page rendered on the screen
 brings up an additional sheet to save the HTML file
 saves the HTML file in the documents directory
 */
struct WebPageView: View {
    @ObservedObject var webViewModel = WebViewModel()
    let webView = WKWebView()
    @State private var urlString: String = "https://www.apple.com"
    @State private var showSaveSheet: Bool = false
    @State private var filename: String = ""

    var body: some View {
        VStack {
            Text("Web Page Viewer")
                .font(.title)
                .fontWeight(.heavy)
            HStack {
                TextField("Enter URL", text: $urlString)
                    .foregroundColor(.blue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            }
//            .padding(.top)
            HStack {
                Button(action: {
                    if let url = URL(string: urlString) {
                        webView.load(URLRequest(url: url))
                    }
                }) {
                    Text("Go")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .controlSize(.mini)
//                        .frame(width: 60, height: 40)
                }
                .padding(.trailing)
                Button(action: {
                    showSaveSheet = true
                }) {
                    Text("Save HTML")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
//                        .frame(width: 120, height: 40)
                }
                .padding(.trailing)
                .sheet(isPresented: $showSaveSheet) {
                    SaveHTMLSheet(showSaveSheet: $showSaveSheet, filename: $filename) {
                        webViewModel.extractHTMLContent(from: webView, filename: filename)
                    }
                }
            }
            
            WebView(webView: webView, webViewModel: webViewModel)
            
//            ScrollView {
//                Text(webViewModel.htmlContent)
//                    .padding()
//            }
        }
    }
}

/**
 creates a web UI view as a full desktop browser
 */
struct WebView: UIViewRepresentable {
    let webView: WKWebView
    let webViewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

/**
 extracts and saves the HTML files from web view
 */
class WebViewModel: ObservableObject {
    @Published var htmlContent: String = ""

    func extractHTMLContent(from webView: WKWebView, filename: String) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { (html: Any?, error: Error?) in
            if let html = html as? String {
                DispatchQueue.main.async {
                    self.htmlContent = html
                    self.saveHTMLToFile(htmlContent: html, filename: filename)
                }
            }
        }
    }

    func saveHTMLToFile(htmlContent: String, filename: String) {
        let fileName = filename.isEmpty ? "webpage.html" : "\(filename).html"
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(fileName)
            do {
                try htmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
                print("HTML content saved to \(fileURL)")
            } catch {
                print("Error saving HTML content: \(error)")
            }
        }
    }
}

/**
 creates the save HTML sheet
 saves the HTML file in documents directory
 */
struct SaveHTMLSheet: View {
    @Binding var showSaveSheet: Bool
    @Binding var filename: String
    var onSave: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Filename")) {
                    TextField("Enter filename", text: $filename)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .navigationTitle("Save HTML")
            .navigationBarItems(leading: Button("Cancel") {
                showSaveSheet = false
            })
            .navigationBarItems(trailing: Button("Save") {
                onSave()
                showSaveSheet = false
            })
        }
    }
}

