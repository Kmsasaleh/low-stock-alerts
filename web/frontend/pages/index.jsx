import { useRef, useState } from "react";
import { useQuery } from "react-query";
import { useAppBridge } from "@shopify/app-bridge-react";

const STATUS = {
  urgent: { tone: "critical", text: "Urgent" },
  watch: { tone: "warning", text: "Watch" },
  ok: { tone: "success", text: "OK" },
};

function plural(count, word) {
  return `${count} ${count === 1 ? word : `${word}s`}`;
}

function productName(row) {
  return row.variant_title ? `${row.product_title} – ${row.variant_title}` : row.product_title;
}

function daysLeftText(row) {
  if (row.reason === "out_of_stock") return "Out of stock";
  if (row.days_left === null) return "No recent sales";
  return `${row.days_left} days`;
}

async function fetchForecast() {
  const response = await fetch("/api/forecast");
  if (!response.ok) throw new Error(`Forecast request failed (${response.status})`);
  return response.json();
}

function SummaryBanner({ urgentCount, watchCount, settings }) {
  if (urgentCount > 0) {
    return (
      <s-banner tone="critical" heading={`${plural(urgentCount, "product")} will run out within ${settings.urgent_days} days`}>
        Reorder these first. They are at the top of the table.
      </s-banner>
    );
  }
  if (watchCount > 0) {
    return (
      <s-banner tone="warning" heading={`${plural(watchCount, "product")} to watch`}>
        These will run out within {settings.watch_days} days at the current sales rate.
      </s-banner>
    );
  }
  return (
    <s-banner tone="success" heading="Nothing is about to run out">
      Every tracked product has more than {settings.watch_days} days of stock at the current sales rate.
    </s-banner>
  );
}

function ForecastTable({ rows, windowDays }) {
  return (
    <s-section padding="none">
      <s-table>
        <s-table-header-row>
          <s-table-header>Product</s-table-header>
          <s-table-header>In stock</s-table-header>
          <s-table-header>{`Sold (last ${windowDays} days)`}</s-table-header>
          <s-table-header>Days left</s-table-header>
          <s-table-header>Status</s-table-header>
        </s-table-header-row>
        <s-table-body>
          {rows.map((row) => (
            <s-table-row key={row.id}>
              <s-table-cell>{productName(row)}</s-table-cell>
              <s-table-cell>{row.inventory_quantity}</s-table-cell>
              <s-table-cell>{row.units_sold}</s-table-cell>
              <s-table-cell>{daysLeftText(row)}</s-table-cell>
              <s-table-cell>
                <s-badge tone={STATUS[row.label].tone}>{STATUS[row.label].text}</s-badge>
              </s-table-cell>
            </s-table-row>
          ))}
        </s-table-body>
      </s-table>
    </s-section>
  );
}

function SettingsForm({ settings, onSaved }) {
  const shopify = useAppBridge();
  const formRef = useRef(null);
  const [saving, setSaving] = useState(false);
  const [errors, setErrors] = useState([]);

  const fieldValue = (name) => formRef.current.querySelector(`[name="${name}"]`).value;

  const save = async () => {
    setSaving(true);
    setErrors([]);
    const response = await fetch("/api/settings", {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        settings: {
          urgent_days: fieldValue("urgent_days"),
          watch_days: fieldValue("watch_days"),
          window_days: fieldValue("window_days"),
          alert_email: fieldValue("alert_email"),
        },
      }),
    });
    setSaving(false);

    if (response.ok) {
      shopify.toast.show("Settings saved");
      await onSaved();
    } else if (response.status === 422) {
      setErrors((await response.json()).errors);
    } else {
      shopify.toast.show("Could not save settings", { isError: true });
    }
  };

  return (
    <s-section heading="Alert settings">
      <div ref={formRef}>
        <s-stack gap="base">
          {errors.length > 0 && <s-banner tone="critical">{errors.join(" ")}</s-banner>}
          <s-number-field label="Urgent when stock runs out within (days)" name="urgent_days" value={String(settings.urgent_days)} min="0" />
          <s-number-field label="Watch when stock runs out within (days)" name="watch_days" value={String(settings.watch_days)} min="0" />
          <s-number-field label="Sales window used for the forecast (days, max 60)" name="window_days" value={String(settings.window_days)} min="1" max="60" />
          <s-email-field label="Alert email (optional)" name="alert_email" value={settings.alert_email ?? ""} />
          <s-button variant="primary" onClick={save} loading={saving ? true : undefined}>
            Save settings
          </s-button>
        </s-stack>
      </div>
    </s-section>
  );
}

export default function HomePage() {
  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["forecast"],
    queryFn: fetchForecast,
    refetchOnWindowFocus: false,
  });

  if (isLoading) {
    return (
      <s-page heading="Low-stock alerts">
        <s-section>
          <s-text>Loading forecast…</s-text>
        </s-section>
      </s-page>
    );
  }

  if (isError) {
    return (
      <s-page heading="Low-stock alerts">
        <s-banner tone="critical" heading="Could not load the forecast">
          Reload the page to try again.
        </s-banner>
      </s-page>
    );
  }

  return (
    <s-page heading="Low-stock alerts">
      <SummaryBanner urgentCount={data.urgent_count} watchCount={data.watch_count} settings={data.settings} />
      <ForecastTable rows={data.rows} windowDays={data.settings.window_days} />
      <SettingsForm settings={data.settings} onSaved={refetch} />
    </s-page>
  );
}
