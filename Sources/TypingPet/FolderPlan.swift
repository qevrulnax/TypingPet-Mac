import Foundation

enum FolderImportError: LocalizedError {
    case missingIdle, ambiguous(String), invalidImage
    var errorDescription: String? {
        switch self {
        case .missingIdle: return "未找到待机图片。请选择直接包含 basic、idle 或待机 图片的文件夹，先解压 ZIP；支持 PNG/GIF/APNG/WebP/JPEG。"
        case .ambiguous(let name): return "发现多张同名状态图片（\(name)），请每个状态只保留一个文件后重试。"
        case .invalidImage: return "某个素材无法解码、不是普通文件或超过 30 MB；此次导入没有改变现有角色。"
        }
    }
}
struct FolderPlan {
    let idle: URL
    let left: URL?
    let right: URL?
    let poses: [URL]
    var files: [URL] { Array(Set([idle] + [left, right].compactMap { $0 } + poses)).sorted { $0.lastPathComponent < $1.lastPathComponent } }
    init(files: [URL]) throws {
        let images = files.filter { ["png", "apng", "gif", "webp", "jpg", "jpeg"].contains($0.pathExtension.lowercased()) }
        func find(_ aliases: [String]) throws -> URL? {
            let matches = images.filter { aliases.contains($0.deletingPathExtension().lastPathComponent.lowercased()) }
            guard matches.count <= 1 else { throw FolderImportError.ambiguous(aliases[0]) }
            return matches.first
        }
        guard let base = try find(["basic", "idle", "待机"]) else { throw FolderImportError.missingIdle }
        idle = base
        left = try find(["left", "左手"])
        right = try find(["right", "右手"])
        let t = try find(["t", "tpose", "t-pose"])
        let space = try find(["space", "太空"])
        let celebrate = try find(["1", "celebrate", "庆祝"])
        if let t { poses = [t, t, space ?? t, t, celebrate ?? t] }
        else { poses = [space, celebrate].compactMap { $0 } }
    }
}
