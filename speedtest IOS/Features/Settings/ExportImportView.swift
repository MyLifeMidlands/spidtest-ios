import SwiftUI
import CoreImage.CIFilterBuiltins

struct ExportImportView: View {
    @ObservedObject private var serverStore = ServerStore.shared
    @State private var selectedServerID: UUID?
    @State private var qrImage: UIImage?
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var importText = ""
    @State private var importResult: String?
    @State private var showImportSection = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Export section
                        exportSection

                        // QR code display
                        if let qr = qrImage {
                            qrCodeSection(qr)
                        }

                        // Import section
                        importSection
                    }
                    .padding(.horizontal, Theme.Layout.screenPadding)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(String(localized: "Export / Import"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    // MARK: - Export

    private var exportSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Export Server"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                if serverStore.servers.isEmpty {
                    Text(String(localized: "No servers to export"))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                } else {
                    // Server picker
                    ForEach(serverStore.servers) { server in
                        Button {
                            selectedServerID = server.id
                            generateQR(for: server)
                        } label: {
                            HStack {
                                if let flag = server.flagEmoji {
                                    Text(flag)
                                }
                                Text(server.name)
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)

                                Spacer()

                                if selectedServerID == server.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if server.id != serverStore.servers.last?.id {
                            Divider().background(Theme.Colors.surfaceLight)
                        }
                    }

                    // Export All button
                    if serverStore.servers.count > 1 {
                        Divider().background(Theme.Colors.surfaceLight)

                        Button {
                            exportAll()
                        } label: {
                            HStack {
                                Image(systemName: "list.bullet")
                                    .foregroundStyle(Theme.Colors.primary)
                                Text(String(localized: "Share All Servers"))
                                    .font(Theme.Fonts.body)
                                    .foregroundStyle(Theme.Colors.primary)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(Theme.Colors.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - QR Code

    private func qrCodeSection(_ image: UIImage) -> some View {
        VStack(spacing: 12) {
            GlassCard {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    if let server = serverStore.servers.first(where: { $0.id == selectedServerID }) {
                        Text(server.name)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 12) {
                Button {
                    if let server = serverStore.servers.first(where: { $0.id == selectedServerID }) {
                        shareText = buildVLESSURI(server)
                        showShareSheet = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(String(localized: "Share URI"))
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.primary.opacity(0.15))
                    )
                }

                Button {
                    if let server = serverStore.servers.first(where: { $0.id == selectedServerID }) {
                        UIPasteboard.general.string = buildVLESSURI(server)
                        importResult = String(localized: "Copied to clipboard")
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc")
                        Text(String(localized: "Copy"))
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.primary.opacity(0.15))
                    )
                }
            }
        }
    }

    // MARK: - Import

    private var importSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(Theme.Colors.primary)
                    Text(String(localized: "Import Server"))
                        .font(Theme.Fonts.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                }

                TextField(String(localized: "Paste VLESS URI or subscription URL"), text: $importText, axis: .vertical)
                    .font(Theme.Fonts.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .lineLimit(3...6)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.Colors.surfaceLight.opacity(0.5))
                    )

                HStack(spacing: 12) {
                    // Paste from clipboard
                    Button {
                        if let clipboard = UIPasteboard.general.string {
                            importText = clipboard
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text(String(localized: "Paste"))
                        }
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    // Import button
                    Button {
                        Task { await performImport() }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(String(localized: "Import"))
                        }
                        .font(Theme.Fonts.body)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Theme.Colors.primary)
                        )
                    }
                    .disabled(importText.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if let result = importResult {
                    Text(result)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func generateQR(for server: VLESSConfig) {
        let uri = buildVLESSURI(server)
        qrImage = generateQRCode(from: uri)
    }

    private func exportAll() {
        let uris = serverStore.servers.map { buildVLESSURI($0) }
        shareText = uris.joined(separator: "\n")
        showShareSheet = true
    }

    private func performImport() async {
        let text = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        do {
            let count = try await serverStore.importFromInput(text)
            importResult = String(format: String(localized: "%d server(s) imported"), count)
            importText = ""
        } catch {
            importResult = error.localizedDescription
        }
    }

    private func buildVLESSURI(_ config: VLESSConfig) -> String {
        var params: [String] = []
        params.append("encryption=\(config.encryption)")
        params.append("security=\(config.security)")
        params.append("type=\(config.network)")

        if let flow = config.flow, !flow.isEmpty { params.append("flow=\(flow)") }
        if let sni = config.sni, !sni.isEmpty { params.append("sni=\(sni)") }
        if let fp = config.fingerprint, !fp.isEmpty { params.append("fp=\(fp)") }
        if let pbk = config.publicKey, !pbk.isEmpty { params.append("pbk=\(pbk)") }
        if let sid = config.shortId, !sid.isEmpty { params.append("sid=\(sid)") }
        if let spx = config.spiderX, !spx.isEmpty { params.append("spx=\(spx.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? spx)") }
        if let alpn = config.alpn, !alpn.isEmpty { params.append("alpn=\(alpn.joined(separator: ","))") }
        if let path = config.wsPath, !path.isEmpty { params.append("path=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path)") }
        if let host = config.wsHost, !host.isEmpty { params.append("host=\(host)") }
        if let sn = config.grpcServiceName, !sn.isEmpty { params.append("serviceName=\(sn)") }

        let query = params.joined(separator: "&")
        let fragment = config.name.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? config.name

        return "vless://\(config.uuid)@\(config.address):\(config.port)?\(query)#\(fragment)"
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
