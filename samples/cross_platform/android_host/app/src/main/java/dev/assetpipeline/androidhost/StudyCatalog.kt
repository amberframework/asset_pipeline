package dev.assetpipeline.androidhost

data class StudySpec(
    val slug: String,
    val title: String,
    val renderer: String,
    val priority: String,
    val lane: String,
    val status: String,
    val summary: String
)

object StudyCatalog {
    private val studies = listOf(
        StudySpec(
            slug = "buttons",
            title = "Material Buttons",
            renderer = "UI::Button",
            priority = "P0",
            lane = "material-defaults",
            status = "pending_acceptance",
            summary = "Primary, tonal, outlined, and text button defaults."
        ),
        StudySpec(
            slug = "text-fields",
            title = "Material Text Fields",
            renderer = "UI::TextField",
            priority = "P0",
            lane = "material-defaults",
            status = "pending_acceptance",
            summary = "Filled and outlined entry surfaces with helper copy."
        ),
        StudySpec(
            slug = "cards",
            title = "Material Cards",
            renderer = "UI::Card",
            priority = "P0",
            lane = "material-defaults",
            status = "accepted",
            summary = "Surface, outlined, and elevated card treatments."
        ),
        StudySpec(
            slug = "dialogs",
            title = "Material Dialogs",
            renderer = "UI::Alert / UI::ConfirmationDialog",
            priority = "P0",
            lane = "material-defaults",
            status = "pending_acceptance",
            summary = "Inline validation previews for alert and confirmation flows."
        ),
        StudySpec(
            slug = "app-bars",
            title = "Top App Bars",
            renderer = "UI::Toolbar",
            priority = "P0",
            lane = "material-defaults",
            status = "pending_acceptance",
            summary = "Small and medium app bar structure for study captures."
        ),
        StudySpec(
            slug = "interaction-smoke",
            title = "Interaction Smoke",
            renderer = "Internal Android callback study",
            priority = "P2",
            lane = "internal-smoke",
            status = "internal_smoke",
            summary = "Host-only callback verification surface for taps, toggles, sliders, and radios."
        ),
        StudySpec(
            slug = "selection-controls",
            title = "Selection Controls",
            renderer = "UI::Picker / UI::SearchField / UI::Stepper",
            priority = "P1",
            lane = "material-defaults",
            status = "pending_acceptance",
            summary = "Menu, segmented, inline, search, and stepper selection flows."
        ),
        StudySpec(
            slug = "transient-surfaces",
            title = "Transient Surfaces",
            renderer = "UI::Sheet / UI::Popover / UI::Snackbar",
            priority = "P1",
            lane = "android-owned-surfaces",
            status = "pending_acceptance",
            summary = "Bottom sheet, popover, and snackbar compositions with callbacks."
        ),
        StudySpec(
            slug = "share-color",
            title = "Share and Color",
            renderer = "UI::ActivityView / UI::ColorPicker",
            priority = "P1",
            lane = "android-owned-surfaces",
            status = "pending_acceptance",
            summary = "Renderer-backed share-sheet preview and palette selection study."
        ),
        StudySpec(
            slug = "webview",
            title = "Embedded Web Surface",
            renderer = "UI::WebViewComponent",
            priority = "P0",
            lane = "placeholder-elimination",
            status = "pending_acceptance",
            summary = "Native WebView mount with Material frame and metadata."
        ),
        StudySpec(
            slug = "map-view",
            title = "Map Surface",
            renderer = "UI::MapView",
            priority = "P0",
            lane = "placeholder-elimination",
            status = "pending_acceptance",
            summary = "Native map-study composition for route and pin validation."
        ),
        StudySpec(
            slug = "video-player",
            title = "Video Surface",
            renderer = "UI::VideoPlayer",
            priority = "P0",
            lane = "placeholder-elimination",
            status = "pending_acceptance",
            summary = "Native video player chrome with overlay controls."
        ),
        StudySpec(
            slug = "chart-view",
            title = "Chart Surface",
            renderer = "UI::ChartView",
            priority = "P0",
            lane = "placeholder-elimination",
            status = "pending_acceptance",
            summary = "Bar, line, and pie study cards rendered from Android primitives."
        )
    )

    fun bySlug(slug: String?): StudySpec {
        return studies.firstOrNull { it.slug == slug } ?: studies.first()
    }
}
