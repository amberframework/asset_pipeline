package dev.assetpipeline.androidhost

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import com.google.android.material.chip.Chip
import dev.assetpipeline.androidhost.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var study: StudySpec
    private var storyText: String = DEFAULT_STORY
    private val rendererRefreshHandler = Handler(Looper.getMainLooper())
    private val rendererRefreshRunnable = Runnable {
        if (!isFinishing && !isDestroyed) {
            configureRendererCard()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        val requestedAppearance = intent.getStringExtra(EXTRA_STUDY_APPEARANCE)?.lowercase()
        AppCompatDelegate.setDefaultNightMode(
            when (requestedAppearance) {
                "dark" -> AppCompatDelegate.MODE_NIGHT_YES
                "light" -> AppCompatDelegate.MODE_NIGHT_NO
                else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
            }
        )

        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        study = StudyCatalog.bySlug(intent.getStringExtra(EXTRA_STUDY_SLUG))
        val appearance = requestedAppearance ?: "system"
        storyText = intent.getStringExtra(EXTRA_STUDY_STORY) ?: DEFAULT_STORY

        binding.toolbar.subtitle = study.slug
        binding.studyTitle.text = study.title
        binding.studySubtitle.text = study.summary
        binding.mountTitle.text = study.renderer
        binding.mountSummary.text =
            "Host shell ready. This mount card is where the Crystal Android renderer attaches native study content for ${study.slug}."
        binding.footnote.text =
            "Validation status: ${study.status}. Story: $storyText. The screenshot ledger should only be promoted after this mount contains renderer output."

        addChip("Priority ${study.priority}")
        addChip("Lane ${study.lane}")
        addChip("Appearance $appearance")
        addChip("Status ${study.status}")

        CrystalBridge.callbackObserver = { scheduleRendererRefresh() }

        configureRendererCard()
    }

    override fun onDestroy() {
        rendererRefreshHandler.removeCallbacks(rendererRefreshRunnable)
        if (CrystalBridge.callbackObserver != null) {
            CrystalBridge.callbackObserver = null
        }
        super.onDestroy()
    }

    private fun scheduleRendererRefresh() {
        rendererRefreshHandler.removeCallbacks(rendererRefreshRunnable)
        rendererRefreshHandler.postDelayed(rendererRefreshRunnable, 250L)
    }

    private fun addChip(text: String) {
        val chip = Chip(this).apply {
            this.text = text
            isCheckable = false
            isClickable = false
        }
        binding.chipGroup.addView(chip)
    }

    private fun configureRendererCard() {
        binding.rendererCard.apply {
            strokeWidth = resources.displayMetrics.density.times(1f).toInt()
            radius = resources.displayMetrics.density.times(28f)
        }

        binding.rendererMount.removeAllViews()

        val renderedView = runCatching {
            CrystalBridge.initialize()
            CrystalBridge.renderStudy(this, study.slug)
        }.getOrNull()

        if (renderedView != null) {
            binding.mountSummary.text =
                "Renderer mount live. This study is being drawn by the Crystal Android renderer for ${study.slug}."
            binding.footnote.text =
                "Validation status: ${study.status}. Story: $storyText. Review renderer output against Material 3 expectations before promoting the ledger."
            renderedView.layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            binding.rendererMount.addView(renderedView)
            return
        }

        val placeholder = TextView(this).apply {
            text = "Renderer mount pending native attach"
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            setPadding(24, 24, 24, 24)
        }
        binding.rendererMount.addView(placeholder)
    }

    companion object {
        const val EXTRA_STUDY_SLUG = "study_slug"
        const val EXTRA_STUDY_APPEARANCE = "study_appearance"
        const val EXTRA_STUDY_STORY = "study_story"

        private const val DEFAULT_STORY = "Cross-platform showcase shell"
    }
}
