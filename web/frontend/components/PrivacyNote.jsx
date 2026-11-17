export function PrivacyNote({ retentionDays }) {
  return (
    <s-section heading="Data and privacy">
      <s-paragraph>
        This app stores your product titles, SKUs and stock levels, the quantity and time of each order line item
        from the last {retentionDays} days, and the alert email address you enter. Older sales are deleted
        automatically.
      </s-paragraph>
      <s-paragraph>
        It does not store customer names, email addresses, shipping addresses or any other customer details. Your
        store's product, sales and settings data is deleted when you uninstall the app.
      </s-paragraph>
    </s-section>
  );
}
