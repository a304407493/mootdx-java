import com.mootdx.localdata.TdxLocalDataReader;
import com.mootdx.model.BarData;
import java.util.List;

public class TestParser {
    public static void main(String[] args) {
        try {
            TdxLocalDataReader reader = new TdxLocalDataReader();
            String filePath = "C:\\new_tdx\\vipdoc\\sz\\minline\\sz399364.lc1";
            System.out.println("Reading file: " + filePath);

            List<BarData> bars = reader.readMinute1File(filePath);
            System.out.println("Total bars read: " + bars.size());

            if (!bars.isEmpty()) {
                System.out.println("\nFirst 5 bars:");
                for (int i = 0; i < Math.min(5, bars.size()); i++) {
                    BarData bar = bars.get(i);
                    System.out.println("Bar " + i + ": date=" + bar.getDate() +
                        ", open=" + bar.getOpen() +
                        ", high=" + bar.getHigh() +
                        ", low=" + bar.getLow() +
                        ", close=" + bar.getClose() +
                        ", volume=" + bar.getVolume() +
                        ", amount=" + bar.getAmount());
                }

                System.out.println("\nLast 5 bars:");
                for (int i = Math.max(0, bars.size() - 5); i < bars.size(); i++) {
                    BarData bar = bars.get(i);
                    System.out.println("Bar " + i + ": date=" + bar.getDate() +
                        ", open=" + bar.getOpen() +
                        ", high=" + bar.getHigh() +
                        ", low=" + bar.getLow() +
                        ", close=" + bar.getClose());
                }
            }
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
