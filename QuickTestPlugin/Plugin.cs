using System.IO;
using System.Linq;
using System.Threading.Tasks;
using BepInEx;
using BepInEx.Logging;
using HarmonyLib;
using RhythmRift;
using Shared;
using Shared.Analytics;
using Shared.SceneLoading;
using Shared.SceneLoading.Payloads;
using Shared.TrackData;
using Shared.TrackSelection;
using Shared.UGC.Local;
using Shared.UGC.Steam;
using Shared.Utilities;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace QuickTest;

[BepInPlugin(MyPluginInfo.PLUGIN_GUID, MyPluginInfo.PLUGIN_NAME, MyPluginInfo.PLUGIN_VERSION)]
public class QuickTestPlugin : BaseUnityPlugin
{
    internal static new ManualLogSource Logger;

    public const string ALLOWED_VERSIONS = "1.11.1 1.10.0 1.8.0 1.7.1 1.7.0";
    public static string[] AllowedVersions => ALLOWED_VERSIONS.Split(' ');

    public static float timer = 0;

    private void Awake()
    {
        
        // Plugin startup logic
        Logger = base.Logger;
        Logger.LogInfo($"Plugin {MyPluginInfo.PLUGIN_GUID} is loaded!");

        var gameVersion = BuildInfoHelper.Instance.BuildId.Split('-')[0];

        Logger.LogInfo("Initialising config");

        QuickTest.Config.Initialize(Config);
        Logger.LogInfo("Initialised config");
        if (!AllowedVersions.Contains(gameVersion) && !QuickTest.Config.General.DisableVersionCheck.Value)
        {
            Logger.LogInfo("Invalid game version, ask for an update or disable version check in config");
            return;
        }
        else
        {
            Harmony.CreateAndPatchAll(typeof(QuickTestPlugin));
        }
        Logger.LogInfo("Finished Init"); 
    }

    [HarmonyPatch(typeof(RRStageController), "Update")]
    [HarmonyPostfix]
    public static void StageUpdate()
    {
        CheckQuickplay();
    }

    [HarmonyPatch(typeof(CustomTracksSelectionSceneController), "Update")]
    [HarmonyPostfix]
    public static void TrackSelectUpdate()
    {
        CheckQuickplay();
    }

    public static void CheckQuickplay()
    {
        if( SceneLoadingController.Instance.IsShowingLoadingScreen ) return;
        string path = LocalUgcTrackProvider.BasePath + "/rifted_utils_quick_test/quick_test.txt";
        if( FileUtils.IsFile( path ))
        {
            string[] quick_test_data = FileUtils.ReadString(path).Split("\n");
            GoToSelectedStage(quick_test_data[0], int.Parse(quick_test_data[1]), int.Parse(quick_test_data[2]) );

            File.Delete( path );
        }   
    }

    public static void GoToSelectedStage(string track, int diff, int beat)
    {
        string level_id = "UGC" + track;
        Logger.LogInfo(level_id);

        LocalTrackMetadata trackMetadata = LocalUgcTrackProvider._instance.GetTrackByLevelIdSync( level_id ) as LocalTrackMetadata;
        Logger.LogInfo("Got track metadata");

        ITrackDifficulty trackDiff = trackMetadata.DifficultyInformation[diff];

        Logger.LogInfo("Got track variant");
        
        if (trackMetadata != null && trackDiff != null)
        {
            
            RRDynamicScenePayload rRDynamicScenePayload = RRDynamicScenePayload.FromMetadata(trackMetadata, trackDiff, TrackMetadataUtils.ResolveAudioChannel(trackMetadata, ""));
            rRDynamicScenePayload.IsPracticeMode = true;
            rRDynamicScenePayload.SetPracticeModeBeatRange(beat, trackMetadata.BeatCount.Value );
            rRDynamicScenePayload.SetPracticeModeSpeedAdjustment( SpeedModifier.OneHundredPercent );
            
            Logger.LogInfo("Setting scenes...");
            
            SceneLoadData.SetCurrentScenePayload(rRDynamicScenePayload);
            SceneLoadData.SetReturnScenePayload(CreateReturnScenePayload(level_id));

            Logger.LogInfo("Trying to get current payload... ");
            if (SceneLoadData.TryGetCurrentPayload(out var payload))
            {
                Logger.LogInfo("Going to RRScene");
                SceneLoadingController.Instance.GoToScene(payload.GetDestinationScene());
            }
        } else
        {
            Logger.LogInfo("Invalid stage");
        }
    }

    public static TrackSelectionScenePayload CreateReturnScenePayload(string levelId)
    {
        TrackSelectionScenePayload trackSelectionScenePayload = ScriptableObject.CreateInstance<TrackSelectionScenePayload>();
        trackSelectionScenePayload.SetDestinationScene("CustomTracksMenu");
        trackSelectionScenePayload.Initialize(levelId, 0, TrackSortingOrder.TitleDescending, true, isRemixMode: false);
        return trackSelectionScenePayload;
    }

}
