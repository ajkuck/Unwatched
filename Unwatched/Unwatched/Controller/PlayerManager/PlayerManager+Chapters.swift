//
//  PlayerManager+Chapters.swift
//  Unwatched
//

import Foundation
import SwiftUI
import OSLog
import SwiftData
import UnwatchedShared

extension PlayerManager {

    @MainActor
    var previousChapterDisabled: Bool {
        previousChapter == nil && currentChapter == nil
    }

    @MainActor
    func monitorChapters(time: Double) {
        currentTime = time
        if let endTime = currentEndTime, time >= endTime {
            handleChapterChange()
        }
        if let current = currentChapter, time < current.startTime {
            handleChapterChange()
        }
    }

    @MainActor
    func handleChapterChange() {
        Logger.log.info("handleChapterChange")
        guard let time = currentTime,
              let video else {
            Logger.log.info("no time or video")
            return
        }

        let chapters = video.sortedChapters
        guard !chapters.isEmpty else {
            currentEndTime = nil // stop monitoring this video for chapters
            Logger.log.info("no info to check for chapters")
            return
        }

        // current chapter
        guard let current = chapters.first(where: { chapter in
            return chapter.startTime <= time && time < (chapter.endTime ?? 0)
        }) else {
            currentEndTime = nil
            return
        }

        // next chapter
        let next = chapters.first(where: { chapter in
            chapter.startTime > current.startTime
        })
        let nextActive = chapters.first(where: { chapter in
            chapter.startTime > current.startTime && chapter.isActive
        })
        nextChapter = nextActive
        if !current.isActive {
            if let nextActive {
                Logger.log.info("skip to next chapter: \(nextActive.titleTextForced)")
                seekPosition = nextActive.startTime
            } else if let duration = video.duration {
                seekPosition = duration - 0.5
            }
        }

        // previous chapter
        let previous = chapters.last(where: { chapter in
            chapter.startTime < current.startTime && chapter.isActive
        })
        previousChapter = previous

        withAnimation {
            currentChapter = current
        }
        currentEndTime = next?.startTime
    }

    @MainActor
    func setChapter(_ chapter: Chapter) {
        seekPosition = chapter.startTime
        currentTime = chapter.startTime
        currentChapter = chapter
        handleChapterChange()
    }

    @MainActor
    func goToNextChapter() -> Bool {
        if let next = nextChapter {
            setChapter(next)
            return true
        }
        return false
    }

    @MainActor
    func goToPreviousChapter() -> Bool {
        guard let current = currentChapter else {
            Logger.log.warning("goToPreviousChapter: No current chapter found")
            return false
        }

        if let currentTime = currentTime,
           (currentTime - current.startTime) >= Const.previousChapterDelaySeconds * playbackSpeed {
            setChapter(current)
            return true
        } else if previousChapter == nil {
            setChapter(current)
            return true
        }

        if let previous = previousChapter {
            setChapter(previous)
            return true
        }
        return false
    }

    @MainActor
    func handleChapterRefresh(forceRefresh: Bool = false) {
        let settingOn = UserDefaults.standard.bool(forKey: Const.mergeSponsorBlockChapters)
        if !settingOn {
            return
        }

        Logger.log.info("handleChapterRefresh")

        guard let videoId = video?.persistentModelID,
              let youtubeId = video?.youtubeId else {
            Logger.log.warning("Not enough info to enrich chapters")
            return
        }

        let chapters = (video?.chapters ?? []).sorted(by: { $0.startTime < $1.startTime })
        let sendableChapters = chapters.map(\.toExport)
        let duration = video?.duration
        if let mergedChapters = video?.mergedChapters {
            ChapterService.skipSponsorSegments(in: mergedChapters)
            self.handleChapterChange()
        }

        Task {
            do {
                guard var newChapters = try await ChapterService
                        .mergeOrGenerateChapters(
                            youtubeId: youtubeId,
                            videoId: videoId,
                            videoChapters: sendableChapters,
                            duration: duration,
                            forceRefresh: forceRefresh
                        ) else {
                    Logger.log.info("SponsorBlock: Not updating merged chapters")
                    return
                }
                Logger.log.info("SponsorBlock: Refreshed")
                ChapterService.skipSponsorSegments(in: &newChapters)

                let modelContext = DataProvider.newContext()
                guard let video = modelContext.model(for: videoId) as? Video else {
                    Logger.log.info("handleChapterRefresh: no video")
                    return
                }

                ChapterService.updateIfNeeded(newChapters, video, modelContext)
                try modelContext.save()
            } catch {
                Logger.log.error("Error while merging chapters: \(error)")
            }
            self.handleChapterChange()
        }
    }

    @MainActor
    func ensureStartPositionWorksWithChapters(_ time: Double) -> Double {
        guard let video = video else {
            Logger.log.warning("ensureStartPositionWorksWithChapters: no video")
            return time
        }
        // regular chapter is active, time is okay
        if video.sortedChapters.first(
            where: {
                $0.isActive && $0.startTime <= time
            }) != nil {
            return time
        }
        // no active chapter found, try to find the first chapter with a start time after the current time
        if let nextChapter = video.sortedChapters.first(
            where: {
                $0.isActive && $0.startTime > time
            }) {
            return nextChapter.startTime
        }
        return time
    }
}
