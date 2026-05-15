//
//  L10n.swift
//  1AIMoodBoardPhotoApp
//

import Foundation

enum L10n {
    fileprivate static func tr(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key))
    }

    enum Common {
        static var back: String { tr("common.back") }
        static var cancel: String { tr("common.cancel") }
        static var close: String { tr("common.close") }
        static var continueAction: String { tr("common.continue") }
        static var delete: String { tr("common.delete") }
        static var error: String { tr("common.error") }
        static var getStarted: String { tr("common.get_started") }
        static var ok: String { tr("common.ok") }
        static var tryAgain: String { tr("common.try_again") }
    }

    enum Tab {
        static var home: String { tr("tab.home") }
        static var myPhotos: String { tr("tab.my_photos") }
        static var profile: String { tr("tab.profile") }
    }

    enum Home {
        static var allPhotosCardSubtitle: String { tr("home.all_photos_card_subtitle") }
        static var allPhotosCardTitle: String { tr("home.all_photos_card_title") }
        static var allPhotosFooter: String { tr("home.all_photos_footer") }
        static var allPhotosOpen: String { tr("home.all_photos_open") }
        static var emptyCreateFirst: String { tr("home.empty.create_first") }
        static var emptyStartShot: String { tr("home.empty.start_shot") }
        static var emptySubtitle: String { tr("home.empty.subtitle") }
        static var latestShoot: String { tr("home.latest_shoot") }
        static var myShots: String { tr("home.my_shots") }
        static var newShot: String { tr("home.new_shot") }
        static var sessionPhotoCountFormat: String { tr("home.session_photo_count_format") }
        static var title: String { tr("home.title") }
        static var trending: String { tr("home.trending") }
        static var untitled: String { tr("home.untitled") }

        static func sessionPhotoCount(_ count: Int) -> String {
            String(format: sessionPhotoCountFormat, locale: .current, count)
        }
    }

    enum MyPhotos {
        static var createShot: String { tr("my_photos.create_shot") }
        static var deleteConfirmMessage: String { tr("my_photos.delete_confirm_message") }
        static var deleteConfirmTitle: String { tr("my_photos.delete_confirm_title") }
        static var deletePhoto: String { tr("my_photos.delete_photo") }
        static var emptySubtitle: String { tr("my_photos.empty_subtitle") }
        static var emptyTitle: String { tr("my_photos.empty_title") }
        static var saveGallery: String { tr("my_photos.save_gallery") }
        static var share: String { tr("my_photos.share") }
        static var title: String { tr("my_photos.title") }
        static var untitledPrompt: String { tr("my_photos.untitled_prompt") }
    }

    enum Shoot {
        static var addPhoto: String { tr("shoot.add_photo") }
        static var close: String { tr("shoot.close") }
        static var replacePhoto: String { tr("shoot.replace_photo") }
        static var selfieSubtitle: String { tr("shoot.selfie_subtitle") }
        static var selfieTitle: String { tr("shoot.selfie_title") }
        static var sessionTitleCustomPrefix: String { tr("shoot.session_title.custom_prefix") }
        static var step1: String { tr("shoot.step1") }
        static var step2: String { tr("shoot.step2") }
        static var step3: String { tr("shoot.step3") }
        static var tip1: String { tr("shoot.tip1") }
        static var tip2: String { tr("shoot.tip2") }
        static var tip3: String { tr("shoot.tip3") }
        static var tip4: String { tr("shoot.tip4") }
        static var tipsTitle: String { tr("shoot.tips_title") }
    }

    enum Style {
        static var customHeading: String { tr("style.custom_heading") }
        static var example: String { tr("style.example") }
        static var placeholder: String { tr("style.placeholder") }
        static var presetsHeading: String { tr("style.presets_heading") }
        static var title: String { tr("style.title") }
    }

    enum Processing {
        static var cancel: String { tr("processing.cancel") }
    }

    enum Gallery {
        static var missingImageError: String { tr("gallery.error.missing_image") }
        static var generateNew: String { tr("gallery.generate_new") }
        static var noImage: String { tr("gallery.no_image") }
        static var savePhotos: String { tr("gallery.save_photos") }
        static var savedToast: String { tr("gallery.saved_toast") }
    }

    enum Banana {
        static var goPurchase: String { tr("banana.go_purchase") }
        static var outMessage: String { tr("banana.out_message") }
        static var outTitle: String { tr("banana.out_title") }
        static var toolbarBuyA11y: String { tr("banana.toolbar.a11y") }
        static var welcomeMessage: String { tr("banana.welcome_message") }
        static var welcomeTitle: String { tr("banana.welcome_title") }
    }

    enum Profile {
        static var activity: String { tr("profile.activity") }
        static var alertPurchase: String { tr("profile.alert_purchase") }
        static var alertReset: String { tr("profile.alert_reset") }
        static var alertRestore: String { tr("profile.alert_restore") }
        static var balance: String { tr("profile.balance") }
        static var bananasSpent: String { tr("profile.bananas_spent") }
        static var buyBananas: String { tr("profile.buy_bananas") }
        static var cardBananas: String { tr("profile.card_bananas") }
        static var danger: String { tr("profile.danger") }
        static var generationsLibrary: String { tr("profile.generations_library") }
        static var privacy: String { tr("profile.privacy") }
        static var rate: String { tr("profile.rate") }
        static var reloadProducts: String { tr("profile.reload_products") }
        static var resetAll: String { tr("profile.reset_all") }
        static var resetDialogTitle: String { tr("profile.reset_dialog_title") }
        static var resetDone: String { tr("profile.reset_done") }
        static var restore: String { tr("profile.restore") }
        static var restoreDone: String { tr("profile.restore_done") }
        static var support: String { tr("profile.support") }
        static var terms: String { tr("profile.terms") }
        static var title: String { tr("profile.title") }
    }

    enum Store {
        static var errorCancelled: String { tr("store.error.cancelled") }
        static var errorUnavailable: String { tr("store.error.unavailable") }
        static var errorVerifyFailed: String { tr("store.error.verify_failed") }
        static var headline: String { tr("store.headline") }
        static var packFormat: String { tr("store.pack_format") }
        static var subline: String { tr("store.subline") }
        static var title: String { tr("store.title") }

        static func packTitle(bananas: Int) -> String {
            String(format: packFormat, locale: .current, bananas)
        }
    }

    enum StoreKitConfig {
        static var noProductsLoaded: String { tr("storekit.no_products") }
    }

    enum AppStrings {
        static var notEnoughBananas: String { tr("error.not_enough_bananas") }
    }

    enum Ai {
        static var decodingFailedFormat: String { tr("ai.error.decoding_failed_format") }
        static var generationRejected: String { tr("ai.error.generation_rejected") }
        static var httpFormat: String { tr("ai.error.http_format") }
        static var invalidURL: String { tr("ai.error.invalid_url") }
        static var missingAPIKey: String { tr("ai.error.missing_api_key") }
        static var missingDownload: String { tr("ai.error.missing_download") }
        static var noOutput: String { tr("ai.error.no_output") }
        static var noTaskID: String { tr("ai.error.no_task_id") }
        static var timeout: String { tr("ai.error.timeout") }
        static var validationOneSelfie: String { tr("ai.validation.one_selfie") }
        static var validationPresetOrPrompt: String { tr("ai.validation.preset_or_prompt") }
        static var missingPollURL: String { tr("ai.error.missing_poll_url") }
    }

    enum Alerts {
        static var couldntGenerate: String { tr("alert.couldnt_generate") }
        static var flaggedRequest: String { tr("alert.flagged_request") }
    }

    enum Progress {
        static var done: String { tr("progress.done") }
        static var downloading: String { tr("progress.downloading") }
        static var finalizing: String { tr("progress.finalizing") }
        static var generating: String { tr("progress.generating") }
        static var preparing: String { tr("progress.preparing") }
        static var queued: String { tr("progress.queued") }
        static var uploaded: String { tr("progress.uploaded") }
    }

    enum Onboard {
        static var pageA11yFormat: String { tr("onboard.page_a11y") }

        enum Page1 {
            static var title: String { tr("onboard.page1.title") }
            static var b1: String { tr("onboard.page1.b1") }
            static var b2: String { tr("onboard.page1.b2") }
            static var b3: String { tr("onboard.page1.b3") }
        }

        enum Page2 {
            static var title: String { tr("onboard.page2.title") }
            static var b1: String { tr("onboard.page2.b1") }
            static var b2: String { tr("onboard.page2.b2") }
            static var b3: String { tr("onboard.page2.b3") }
        }

        enum Page3 {
            static var title: String { tr("onboard.page3.title") }
            static var b1: String { tr("onboard.page3.b1") }
            static var b2: String { tr("onboard.page3.b2") }
            static var b3: String { tr("onboard.page3.b3") }
        }

        enum Page4 {
            static var title: String { tr("onboard.page4.title") }
            static var b1: String { tr("onboard.page4.b1") }
            static var b2: String { tr("onboard.page4.b2") }
            static var b3: String { tr("onboard.page4.b3") }
        }

        static func pageAccessibility(current: Int, total: Int) -> String {
            String(format: pageA11yFormat, locale: .current, current, total)
        }
    }

    enum Vibe {
        static var cleanGirl: String { tr("vibe.clean_girl") }
        static var coastal: String { tr("vibe.coastal") }
        static var cottagecore: String { tr("vibe.cottagecore") }
        static var darkAcademia: String { tr("vibe.dark_academia") }
        static var mobWife: String { tr("vibe.mob_wife") }
        static var oldMoney: String { tr("vibe.old_money") }
        static var softGlam: String { tr("vibe.soft_glam") }
        static var sportyChic: String { tr("vibe.sporty_chic") }
        static var streetMinimal: String { tr("vibe.street_minimal") }
        static var y2k: String { tr("vibe.y2k") }
    }
}
