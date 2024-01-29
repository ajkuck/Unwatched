//
//  VideoCrawler.swift
//  Unwatched
//

import Foundation

class VideoCrawler {
    static func parseFeedUrl(_ url: URL, limitVideos: Int?, cutoffDate: Date?) async throws -> RSSParserDelegate {
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = XMLParser(data: data)
        let rssParserDelegate = RSSParserDelegate(limitVideos: limitVideos, cutoffDate: cutoffDate)
        parser.delegate = rssParserDelegate
        parser.parse()
        return rssParserDelegate
    }

    static func loadVideosFromRSS(url: URL, mostRecentPublishedDate: Date?) async throws -> [SendableVideo] {
        print("loadVideosFromRSS", url)
        let rssParserDelegate = try await self.parseFeedUrl(url, limitVideos: nil, cutoffDate: mostRecentPublishedDate)
        return rssParserDelegate.videos
    }

    static func loadSubscriptionFromRSS(feedUrl: URL) async throws -> SendableSubscription {
        let rssParserDelegate = try await self.parseFeedUrl(feedUrl, limitVideos: 0, cutoffDate: nil)
        if var subscriptionInfo = rssParserDelegate.subscriptionInfo {
            subscriptionInfo.link = feedUrl
            return subscriptionInfo
        }
        print("feedUrl", feedUrl)
        throw VideoCrawlerError.subscriptionInfoNotFound
    }

    static func isYtShort(_ title: String, description: String?) -> (isShort: Bool, isLikelyShort: Bool) {
        // search title and desc for #short -> definitly short
        let regexYtShort = #"#[sS]horts"#
        if title.matching(regex: regexYtShort) != nil {
            return (true, false)
        }
        if description?.matching(regex: regexYtShort) != nil {
            return (true, false)
        }

        // shorts seem to have hashtags in the title and a shorter description
        let regexHashtag = #"#[[:alpha:]]{2,}"#
        let titleHasHashtags = title.matching(regex: regexHashtag) != nil
        if titleHasHashtags {
            return (false, true)
        }
        return (false, false)
    }

    static func extractChapters(from description: String, videoDuration: Double?) -> [SendableChapter] {
        let input = description
        do {
            let regex = try NSRegularExpression(pattern: #"\n(\d+(?:\:\d+)+)\s+[-–•]?\s*(.+)"#)
            let range = NSRange(input.startIndex..<input.endIndex, in: input)

            var chapters: [SendableChapter] = []

            regex.enumerateMatches(in: input, options: [], range: range) { match, _, _ in
                if let match = match {
                    let timeRange = Range(match.range(at: 1), in: input)!
                    let titleRange = Range(match.range(at: 2), in: input)!

                    let timeString = String(input[timeRange])
                    let title = String(input[titleRange])
                    if let time = timeToSeconds(timeString) {
                        let chapter = SendableChapter(title: title, startTime: time)
                        chapters.append(chapter)
                    }
                }
            }
            let chatpersWithDuration = setDuration(in: chapters, videoDuration: videoDuration)
            return chatpersWithDuration
        } catch {
            print("Error creating regex: \(error)")
        }
        return []
    }

    static func setDuration(in chapters: [SendableChapter], videoDuration: Double?) -> [SendableChapter] {
        var chapters = chapters
        for index in 0..<chapters.count {
            if index == chapters.count - 1 {
                if let videoDuration = videoDuration {
                    chapters[index].duration = videoDuration - chapters[index].startTime
                    chapters[index].endTime = videoDuration
                } else {
                    chapters[index].duration = nil
                }
            } else {
                chapters[index].endTime = chapters[index + 1].startTime
                chapters[index].duration = chapters[index + 1].startTime - chapters[index].startTime
            }
        }
        return chapters
    }

    static func timeToSeconds(_ time: String) -> Double? {
        let components = time.components(separatedBy: ":")

        switch components.count {
        case 2:
            // Format: mm:ss
            guard let minutes = Double(components[0]),
                  let seconds = Double(components[1]) else {
                return nil
            }
            return minutes * 60 + seconds

        case 3:
            // Format: hh:mm:ss
            guard let hours = Double(components[0]),
                  let minutes = Double(components[1]),
                  let seconds = Double(components[2]) else {
                return nil
            }
            return hours * 3600 + minutes * 60 + seconds

        default:
            return nil
        }
    }
}
